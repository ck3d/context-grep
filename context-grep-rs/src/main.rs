#![allow(clippy::collapsible_if, clippy::needless_range_loop)]

use anyhow::{Context, Result};
use clap::Parser;
use regex::Regex;
use std::path::PathBuf;
use std::process::ExitCode;

mod cli;
mod lang;
mod models;
mod printer;
mod search;

use cli::{Args, Format};
use lang::LanguageManager;
use printer::{Styles, pretty_print};
use search::process_file;

fn main() -> Result<ExitCode> {
    let mut args = Args::parse();
    let re = Regex::new(&args.pattern).context("Invalid regex pattern")?;

    if args.treesitter_dirs.is_empty() {
        args.treesitter_dirs.push(PathBuf::from("."));
    }

    let mut lang_manager = LanguageManager::new(args.treesitter_dirs);
    let mut all_results = Vec::new();
    let mut had_error = false;

    for file_path in args.files {
        if let Err(e) = process_file(&file_path, &re, &mut lang_manager, &mut all_results) {
            eprintln!("Error processing {:?}: {}", file_path, e);
            had_error = true;
        }
    }

    all_results.sort_by(|a, b| {
        a.file
            .cmp(&b.file)
            .then(a.match_info.line.cmp(&b.match_info.line))
    });

    match args.format {
        Format::Json => println!("{}", serde_json::to_string(&all_results)?),
        Format::Pretty => pretty_print(&all_results, &Styles::new(args.color), args.no_icons),
    }

    if had_error {
        Ok(ExitCode::from(2))
    } else {
        Ok(ExitCode::SUCCESS)
    }
}
