use anyhow::{Context, Result};
use regex::Regex;
use std::collections::HashMap;
use std::fs;
use std::path::Path;
use streaming_iterator::StreamingIterator;
use tree_sitter::{Node, Parser as TSParser, Query, QueryCursor};

use crate::lang::{LanguageManager, LANG_MAPPINGS};
use crate::models::{MatchResult, NodeInfo};

pub struct TreeLayer {
    pub lang_name: String,
    pub tree: tree_sitter::Tree,
    pub context_ranges: HashMap<usize, ContextRange>,
    pub ranges: Vec<tree_sitter::Range>,
}

impl TreeLayer {
    pub fn covers(&self, byte_offset: usize) -> bool {
        self.ranges.is_empty()
            || self
                .ranges
                .iter()
                .any(|r| byte_offset >= r.start_byte && byte_offset < r.end_byte)
    }
}

pub struct ContextRange {
    pub start_row: usize,
    pub start_col: usize,
    pub end_row: usize,
    pub end_col: usize,
}

pub fn process_file(
    path: &Path,
    re: &Regex,
    lang_manager: &mut LanguageManager,
    all_results: &mut Vec<MatchResult>,
) -> Result<()> {
    let content = fs::read_to_string(path)?;
    let Ok(tags) = file_identify::tags_from_path(path) else {
        return Ok(());
    };

    let Some(lang_name) = LANG_MAPPINGS
        .iter()
        .find(|(tags_to_check, _)| tags_to_check.iter().any(|t| tags.contains(t)))
        .map(|(_, lang)| *lang)
    else {
        return Ok(());
    };

    let mut layers = Vec::new();
    let mut queue = Vec::new();
    queue.push((lang_name.to_string(), vec![]));

    while let Some((lname, ranges)) = queue.pop() {
        let Ok(lang) = lang_manager.get_language(&lname) else {
            continue;
        };
        let mut parser = TSParser::new();
        parser.set_language(&lang)?;
        if !ranges.is_empty() {
            parser.set_included_ranges(&ranges)?;
        }

        let tree = parser.parse(&content, None).context("Failed to parse")?;
        let root = tree.root_node();

        let context_ranges = lang_manager
            .get_query(&lname, lang.clone(), "context.scm")
            .map(|q| build_context_ranges(root, q, &content))
            .unwrap_or_default();

        if let Some(inj_query) = lang_manager.get_query(&lname, lang.clone(), "injections.scm") {
            let mut cursor = QueryCursor::new();
            let mut matches = cursor.matches(inj_query, root, content.as_bytes());
            let capture_names = inj_query.capture_names();

            while let Some(m) = matches.next() {
                let mut inj_lang = String::new();
                let mut content_node = None;

                for prop in inj_query.property_settings(m.pattern_index) {
                    if prop.key.as_ref() == "injection.language" {
                        if let Some(val) = &prop.value {
                            inj_lang = val.as_ref().to_string();
                        }
                    }
                }

                for cap in m.captures {
                    match capture_names[cap.index as usize] {
                        "injection.language" => {
                            inj_lang =
                                content[cap.node.start_byte()..cap.node.end_byte()].to_string()
                        }
                        "injection.content" => content_node = Some(cap.node),
                        _ => {}
                    }
                }

                if let Some(node) = content_node {
                    if !inj_lang.is_empty() {
                        queue.push((inj_lang, vec![node.range()]));
                    }
                }
            }
        }

        layers.push(TreeLayer {
            lang_name: lname,
            tree,
            context_ranges,
            ranges,
        });
    }

    let lines: Vec<&str> = content.lines().collect();
    for (row, line) in lines.iter().enumerate() {
        if let Some(mat) = re.find(line) {
            let start_col = mat.start();
            let end_col = mat.end();
            let byte_offset = lines[..row].iter().map(|l| l.len() + 1).sum::<usize>() + start_col;
            let match_point = tree_sitter::Point::new(row, start_col);
            let match_end_point = tree_sitter::Point::new(row, end_col);

            let mut best_layer = None;
            for layer in &layers {
                if layer.covers(byte_offset) && (best_layer.is_none() || !layer.ranges.is_empty()) {
                    best_layer = Some(layer);
                }
            }

            let Some(layer) = best_layer else { continue };
            let root = layer.tree.root_node();
            let match_lang = layer.lang_name.as_str();

            let Some(node) = root.descendant_for_point_range(match_point, match_end_point) else {
                continue;
            };

            let mut match_node = node;
            let mut ancestor = Some(node);
            while let Some(curr) = ancestor {
                if is_comment(curr) {
                    match_node = curr;
                } else if is_comment(match_node) {
                    break;
                }
                ancestor = curr.parent();
            }

            let match_info = get_node_info(match_node, &content, match_lang);
            let target_node = find_target_node(match_node);
            let target_info = target_node.map(|n| get_node_info(n, &content, match_lang));

            let mut contexts = Vec::new();
            let mut seen_rows = std::collections::HashSet::new();

            for layer in &layers {
                if !layer.covers(byte_offset) {
                    continue;
                }
                let mut ancestor = layer
                    .tree
                    .root_node()
                    .descendant_for_point_range(match_point, match_end_point);
                while let Some(curr) = ancestor {
                    if let Some(range) = layer.context_ranges.get(&curr.id()) {
                        if seen_rows.insert(range.start_row) {
                            contexts.push(get_context_info(
                                curr,
                                range,
                                &content,
                                &layer.lang_name,
                            ));
                        }
                    }
                    ancestor = curr.parent();
                }
            }

            contexts.sort_by_key(|c| c.line);

            all_results.push(MatchResult {
                file: path.to_string_lossy().to_string(),
                match_info,
                target: target_info,
                context: contexts,
                filetype: lang_name.to_string(),
            });
        }
    }

    Ok(())
}

pub fn build_context_ranges(root: Node, query: &Query, content: &str) -> HashMap<usize, ContextRange> {
    let mut cursor = QueryCursor::new();
    let mut matches = cursor.matches(query, root, content.as_bytes());
    let mut ranges = HashMap::new();

    let captures_names = query.capture_names();

    while let Some(m) = matches.next() {
        let mut context_node = None;
        let mut start_row = None;
        let mut start_col = None;
        let mut end_row = None;
        let mut end_col = None;

        for capture in m.captures {
            let name = captures_names[capture.index as usize];
            let n = capture.node;
            let range = n.range();

            match name {
                "context" => context_node = Some(n),
                "context.start" => {
                    start_row = Some(range.start_point.row);
                    start_col = Some(range.start_point.column);
                }
                "context.final" => {
                    end_row = Some(range.end_point.row);
                    end_col = Some(range.end_point.column);
                }
                "context.end" => {
                    end_row = Some(range.start_point.row);
                    end_col = Some(range.start_point.column);
                }
                _ => {}
            }
        }

        if let Some(cn) = context_node {
            let range = cn.range();
            ranges.insert(
                cn.id(),
                ContextRange {
                    start_row: start_row.unwrap_or(range.start_point.row),
                    start_col: start_col.unwrap_or(range.start_point.column),
                    end_row: end_row.unwrap_or(range.start_point.row + 1),
                    end_col: end_col.unwrap_or(0),
                },
            );
        }
    }

    ranges
}

pub fn is_comment(node: Node) -> bool {
    node.kind().contains("comment")
}

pub fn get_node_info(node: Node, content: &str, language: &str) -> NodeInfo {
    let range = node.range();
    let text = &content[range.start_byte..range.end_byte];
    NodeInfo {
        text: text.to_string(),
        line: range.start_point.row + 1,
        node_type: node.kind().to_string(),
        language: language.to_string(),
    }
}

pub fn get_context_info(node: Node, range: &ContextRange, content: &str, language: &str) -> NodeInfo {
    let text = get_text_range(content, range);
    NodeInfo {
        text,
        line: range.start_row + 1,
        node_type: node.kind().to_string(),
        language: language.to_string(),
    }
}

pub fn get_text_range(content: &str, range: &ContextRange) -> String {
    let lines: Vec<&str> = content.lines().collect();
    if range.start_row >= lines.len() {
        return String::new();
    }

    let mut result = String::new();
    let end_row = range.end_row.min(lines.len().saturating_sub(1));

    for r in range.start_row..=end_row {
        let line = lines[r];
        let start_col = if r == range.start_row {
            range.start_col.min(line.len())
        } else {
            0
        };
        let end_col = if r == range.end_row && range.end_col > 0 {
            range.end_col.min(line.len())
        } else {
            line.len()
        };

        if start_col < end_col {
            result.push_str(&line[start_col..end_col]);
        }
        if r < end_row {
            result.push('\n');
        }
    }

    result.trim_end().to_string()
}

pub fn find_target_node(node: Node) -> Option<Node> {
    let srow = node.range().start_point.row;

    let mut curr = node.prev_named_sibling();
    while let Some(n) = curr {
        let range = n.range();
        if range.start_point.row != srow && range.end_point.row != srow {
            break;
        }
        if !is_comment(n) {
            return Some(n);
        }
        curr = n.prev_named_sibling();
    }

    let mut curr = node.next_named_sibling();
    while let Some(n) = curr {
        if !is_comment(n) {
            return Some(n);
        }
        curr = n.next_named_sibling();
    }

    None
}
