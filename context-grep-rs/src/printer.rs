use crate::cli::ColorChoice;
use crate::models::{MatchResult, NodeInfo, Role, StyledNode};
use std::io::IsTerminal;

pub fn pretty_print(results: &[MatchResult], styles: &Styles, no_icons: bool) {
    if results.is_empty() {
        eprintln!("No matches.");
        return;
    }

    let max_line_val = results
        .iter()
        .flat_map(get_result_nodes)
        .map(|sn| node_max_line(sn.node))
        .max()
        .unwrap_or(1);
    let line_width = max_line_val.to_string().len();

    for result in results {
        let header_str = styles.header(&result.file, result.match_info.line);
        let header_icon = if !no_icons && !result.filetype.is_empty() {
            format!(" {}", styles.dim(get_lang_icon(&result.filetype)))
        } else if !result.filetype.is_empty() {
            format!(" {}", styles.dim(&result.filetype))
        } else {
            String::new()
        };
        println!("{}{}", header_str, header_icon);

        let mut styled_nodes = get_result_nodes(result);
        styled_nodes.sort_by_key(|sn| sn.node.line);

        let mut languages: std::collections::HashSet<&str> = styled_nodes
            .iter()
            .map(|sn| sn.node.language.as_str())
            .collect();
        if !result.filetype.is_empty() {
            languages.insert(&result.filetype);
        }
        let show_inner_icons = languages.len() > 1;

        let mut last_line: Option<usize> = None;

        for sn in &styled_nodes {
            let text = &sn.node.text;
            if text.is_empty() {
                continue;
            }

            let start = sn.node.line;
            let lines: Vec<&str> = text.split('\n').collect();

            if let Some(last) = last_line {
                if start > last + 1 {
                    println!("  {} {}", " ".repeat(line_width), styles.dim("┆"));
                }
            }

            for (offset, line) in lines.iter().enumerate() {
                let current_line_num = start + offset;

                let icon_col = if offset == 0 && show_inner_icons && !no_icons {
                    let icon = get_lang_icon(&sn.node.language);
                    if icon.is_empty() {
                        "  ".to_string()
                    } else {
                        format!("{} ", styles.dim(icon))
                    }
                } else {
                    "  ".to_string()
                };

                let line_num_col = format!("{:>width$}", current_line_num, width = line_width);
                let pipe = styles.pipe("│ ", sn.role);
                let styled_text = styles.text(line, sn.role);

                println!(
                    "{}{}{} {}",
                    icon_col,
                    styles.dim(&line_num_col),
                    pipe,
                    styled_text
                );
            }

            let end_line = start + lines.len() - 1;
            last_line = Some(last_line.map_or(end_line, |last| last.max(end_line)));
        }

        println!();
    }
}

pub struct Styles {
    pub enabled: bool,
}

impl Styles {
    pub fn new(choice: ColorChoice) -> Self {
        let enabled = match choice {
            ColorChoice::Always => true,
            ColorChoice::Never => false,
            ColorChoice::Auto => {
                std::io::stdout().is_terminal() && std::env::var_os("NO_COLOR").is_none()
            }
        };
        Self { enabled }
    }

    pub fn header(&self, file: &str, line: usize) -> String {
        if self.enabled {
            format!("\x1b[1;36m{}:{}\x1b[0m", file, line)
        } else {
            format!("{}:{}", file, line)
        }
    }

    pub fn dim(&self, text: &str) -> String {
        if self.enabled {
            format!("\x1b[2m{}\x1b[0m", text)
        } else {
            text.to_string()
        }
    }

    pub fn pipe(&self, text: &str, role: Role) -> String {
        if !self.enabled {
            return text.to_string();
        }
        match role {
            Role::Match => format!("\x1b[35m{}\x1b[0m", text),
            Role::Target => format!("\x1b[32m{}\x1b[0m", text),
            Role::Context => format!("\x1b[2;34m{}\x1b[0m", text),
        }
    }

    pub fn text(&self, text: &str, role: Role) -> String {
        if !self.enabled {
            return text.to_string();
        }
        match role {
            Role::Match => format!("\x1b[1;35m{}\x1b[0m", text),
            Role::Target => text.to_string(),
            Role::Context => format!("\x1b[2m{}\x1b[0m", text),
        }
    }
}

pub fn get_result_nodes(result: &MatchResult) -> Vec<StyledNode<'_>> {
    let mut nodes = Vec::with_capacity(1 + result.target.is_some() as usize + result.context.len());

    nodes.push(StyledNode {
        node: &result.match_info,
        role: Role::Match,
    });

    if let Some(ref target) = result.target {
        nodes.push(StyledNode {
            node: target,
            role: Role::Target,
        });
    }

    for ctx in &result.context {
        nodes.push(StyledNode {
            node: ctx,
            role: Role::Context,
        });
    }

    nodes
}

pub fn node_max_line(node: &NodeInfo) -> usize {
    node.line + node.text.split('\n').count().saturating_sub(1)
}

pub fn get_lang_icon(lang: &str) -> &'static str {
    match lang.to_lowercase().as_str() {
        "lua" => "",
        "python" => "",
        "markdown" => "",
        "rust" => "",
        "go" => "",
        "javascript" | "js" => "",
        "typescript" | "ts" => "",
        "tsx" => "",
        "c" => "",
        "cpp" | "c++" => "",
        "java" => "",
        "nix" => "",
        "ruby" => "",
        "html" => "",
        "css" => "",
        "scss" => "",
        "json" => "",
        "yaml" => "",
        "toml" => "",
        "bash" | "sh" | "zsh" => "",
        "vim" | "viml" | "vimdoc" => "",
        "php" => "",
        "haskell" => "",
        "scala" => "",
        "kotlin" => "",
        "swift" => "",
        "dockerfile" => "",
        "sql" => "",
        _ => "",
    }
}
