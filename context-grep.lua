local args = _G.arg

if #args < 2 then
  io.stderr:write("Usage: context-grep <pattern> <file>...\n")
  os.exit(1)
end

local pattern = args[1]

local ok_re, re = pcall(vim.regex, pattern)
if not ok_re then
  io.stderr:write("Invalid pattern: '" .. pattern .. "'\n")
  os.exit(1)
end

local function is_comment(node)
  return node:type():find("comment") ~= nil
end

-- First non-comment named sibling reachable via `method` ("prev_named_sibling"
-- or "next_named_sibling"). If `srow` is given, stop once a sibling no longer
-- touches that row (so the search stays on the match's own line).
local function first_named_sibling(node, method, srow)
  local curr = node[method](node)
  while curr do
    if srow then
      local psrow, _, perow = curr:range()
      if psrow ~= srow and perow ~= srow then break end
    end
    if not is_comment(curr) then return curr end
    curr = curr[method](curr)
  end
end

-- Runs the context query once over the whole tree and returns a map from each
-- @context node id to its range {srow, scol, erow, ecol}. Computing this once
-- per file avoids re-running iter_matches over a node's subtree for every
-- ancestor of every match (which was O(matches * depth * subtree)).
local function build_context_ranges(root, query, bufnr)
  local captures = query.captures
  local ranges = {}

  for _, match in query:iter_matches(root, bufnr, 0, -1) do
    local context_node
    local start_row, start_col, end_row, end_col
    for id, n in pairs(match) do
      if type(n) == "table" then n = n[#n] end
      local name = captures[id]
      local msrow, mscol, merow, mecol = n:range()

      if name == "context" then
        context_node = n
      elseif name == "context.start" then
        start_row, start_col = msrow, mscol
      elseif name == "context.final" then
        end_row, end_col = merow, mecol
      elseif name == "context.end" then
        end_row, end_col = msrow, mscol
      end
    end

    if context_node then
      local csrow, cscol = context_node:range()
      -- Default to the context node's own first line; start/final/end captures
      -- override the respective endpoints.
      ranges[context_node:id()] = {
        start_row or csrow,
        start_col or cscol,
        end_row or csrow + 1,
        end_col or 0,
      }
    end
  end

  return ranges
end

-- Returns a list of context objects for a given row
local function get_context_for_line(row, line_str, bufnr, root, context_ranges)
  local col = (line_str:find("%S") or 1) - 1
  local node = root:named_descendant_for_range(row, col, row, col + 1)
  if not node then return {} end

  local contexts = {}
  local seen_rows = {}
  local p = node
  while p do
    local range = context_ranges[p:id()]
    if range and not seen_rows[range[1]] then
      table.insert(contexts, 1, { node = p, range = range })
      seen_rows[range[1]] = true
    end
    p = p:parent()
  end

  local result = {}
  for _, item in ipairs(contexts) do
    local r = item.range
    local srow, erow, ecol = r[1], r[3], r[4]
    if ecol == 0 then erow, ecol = erow - 1, -1 end

    local lines = vim.api.nvim_buf_get_text(bufnr, srow, 0, erow, ecol, {})
    while #lines > 0 and not lines[#lines]:match("%S") do
      table.remove(lines)
    end
    table.insert(result, {
      text = table.concat(lines, "\n"),
      line = srow + 1,
      type = item.node:type()
    })
  end

  return result
end

local function get_node_info(node, bufnr)
  if not node then return nil end
  return {
    text = vim.treesitter.get_node_text(node, bufnr),
    line = (node:range()) + 1,
    type = node:type()
  }
end

local all_results = {}

for i = 2, #args do
  local file = args[i]
  if vim.fn.filereadable(file) == 0 then
    io.stderr:write("File '" .. file .. "' does not exist or is not readable\n")
    goto next_file
  end
  local bufnr = vim.fn.bufadd(file)
  vim.fn.bufload(bufnr)

  local ft = vim.filetype.match({ buf = bufnr })
  if ft then
    vim.bo[bufnr].filetype = ft
  end

  local lang = ft and (vim.treesitter.language.get_lang(ft) or ft)
  if not lang then
    io.stderr:write("No language found for '" .. file .. "'\n")
    goto next_file
  end

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, lang)
  if not (ok and parser) then
    io.stderr:write("No parser found for '" .. lang .. "' in '" .. file .. "'\n")
    goto next_file
  end

  local trees = parser:parse()
  if not (trees and trees[1]) then
    io.stderr:write("Could not parse '" .. file .. "'\n")
    goto next_file
  end
  local root = trees[1]:root()
  local query = vim.treesitter.query.get(lang, "context")
  if not query then
    io.stderr:write("No context query found for '" .. lang .. "' in '" .. file .. "'\n")
    goto next_file
  end

  local context_ranges = build_context_ranges(root, query, bufnr)
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  for j, line_str in ipairs(lines) do
    local row = j - 1
    local s, e = re:match_str(line_str)
    if s then
      local node = root:descendant_for_range(row, s, row, e)
      -- A zero-width match or an out-of-range position yields no node; skip the
      -- line rather than indexing nil below (mirrors the guard in
      -- get_context_for_line).
      if not node then goto next_line end

      -- Find outermost comment node if the match is in a comment
      local match_node = node
      local p = node
      while p do
        if is_comment(p) then
          match_node = p
        elseif is_comment(match_node) then
          break
        end
        p = p:parent()
      end

      local srow = match_node:range()

      -- Target: the code the comment refers to. Search previous siblings first
      -- but bounded to the comment's own line, so a trailing comment
      -- (`local y = 1 -- TODO`) resolves to the code on its left. Otherwise fall
      -- back to following siblings, unbounded, so a block-leading comment
      -- resolves to the code below it (possibly several lines down). The omitted
      -- `srow` on the second call is deliberate: passing it would bound the
      -- forward search to the comment's line and break block-leading targets.
      local target_node = first_named_sibling(match_node, "prev_named_sibling", srow)
        or first_named_sibling(match_node, "next_named_sibling")

      table.insert(all_results, {
        file = file,
        match = get_node_info(match_node, bufnr),
        target = get_node_info(target_node, bufnr),
        context = get_context_for_line(row, line_str, bufnr, root, context_ranges),
        filetype = ft
      })
    end
    ::next_line::
  end
  ::next_file::
end

io.stdout:write(vim.json.encode(all_results))
