use clap::Parser;
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

    #[arg(long, value_enum, default_value_t = Format::Json)]
    pub format: Format,

    #[arg(long, value_enum, default_value_t = ColorChoice::Auto)]
    pub color: ColorChoice,

    #[arg(long)]
    pub no_icons: bool,
}

#[derive(clap::ValueEnum, Clone, Copy, Debug, PartialEq, Eq)]
pub enum Format {
    Json,
    Pretty,
}

#[derive(clap::ValueEnum, Clone, Copy, Debug, PartialEq, Eq)]
pub enum ColorChoice {
    Auto,
    Always,
    Never,
}
