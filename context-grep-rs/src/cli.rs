use clap::{Parser, ValueEnum};
use std::path::PathBuf;

#[derive(Parser, Debug)]
#[command(author, version, about)]
pub struct Args {
    pub pattern: String,
    pub files: Vec<PathBuf>,

    #[arg(
        long = "ts-dir",
        env = "CONTEXT_GREP_NVIM_PLUGIN_DIRS",
        value_delimiter = ':'
    )]
    pub treesitter_dirs: Vec<PathBuf>,

    #[arg(long, value_enum, default_value_t)]
    pub format: Format,

    #[arg(long, value_enum, default_value_t)]
    pub color: ColorChoice,

    #[arg(long)]
    pub no_icons: bool,
}

#[derive(ValueEnum, Clone, Copy, Debug, PartialEq, Eq, Default)]
pub enum Format {
    Json,
    #[default]
    Pretty,
}

#[derive(ValueEnum, Clone, Copy, Debug, PartialEq, Eq, Default)]
pub enum ColorChoice {
    #[default]
    Auto,
    Always,
    Never,
}
