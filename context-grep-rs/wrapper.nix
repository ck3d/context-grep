{
  lib,
  writeShellApplication,
  context-grep,
  vimPlugins,
}:
writeShellApplication {
  name = "context-grep";
  text = ''
    export CONTEXT_GREP_NVIM_PLUGIN_DIRS="${context-grep.nvim-plugin-grammars}:${vimPlugins.nvim-treesitter-context}"
    exec ${lib.getExe context-grep.context-grep-rs} "$@"
  '';
}
