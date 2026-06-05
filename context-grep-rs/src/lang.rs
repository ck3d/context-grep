use anyhow::{Context, Result, anyhow};
use std::collections::HashMap;
use std::fs;
use std::path::PathBuf;
use tree_sitter::{Language, Query};

pub struct LanguageManager {
    treesitter_dirs: Vec<PathBuf>,
    languages: HashMap<String, Language>,
    queries: HashMap<String, Option<Query>>,
    // We need to keep the libraries alive
    _libraries: Vec<libloading::Library>,
}

impl LanguageManager {
    pub fn new(treesitter_dirs: Vec<PathBuf>) -> Self {
        Self {
            treesitter_dirs,
            languages: HashMap::new(),
            queries: HashMap::new(),
            _libraries: Vec::new(),
        }
    }

    pub fn get_language(&mut self, lang_name: &str) -> Result<Language> {
        if let Some(lang) = self.languages.get(lang_name) {
            return Ok(lang.clone());
        }

        let so_name = format!("{}.so", lang_name);

        let path = self
            .treesitter_dirs
            .iter()
            .map(|dir| dir.join("parser").join(&so_name))
            .find(|p| p.exists())
            .ok_or_else(|| {
                anyhow!(
                    "Grammar not found for {} in {:?}",
                    lang_name,
                    self.treesitter_dirs
                )
            })?;

        let lib = unsafe { libloading::Library::new(&path) }
            .with_context(|| format!("Failed to load library {:?}", path))?;

        let symbol_name = format!("tree_sitter_{}", lang_name.replace('-', "_"));
        let lang = unsafe {
            let constructor: libloading::Symbol<unsafe extern "C" fn() -> Language> = lib
                .get(symbol_name.as_bytes())
                .with_context(|| format!("Failed to find symbol {} in {:?}", symbol_name, path))?;
            constructor()
        };

        self._libraries.push(lib);
        self.languages.insert(lang_name.to_string(), lang.clone());
        Ok(lang)
    }

    pub fn get_query(&mut self, lang_name: &str, lang: Language, query_name: &str) -> Option<&Query> {
        let key = format!("{}:{}", lang_name, query_name);
        if !self.queries.contains_key(&key) {
            let query = self.load_query(lang_name, &lang, query_name);
            self.queries.insert(key.clone(), query);
        }
        self.queries[&key].as_ref()
    }

    fn load_query(&self, lang_name: &str, lang: &Language, file_name: &str) -> Option<Query> {
        for dir in &self.treesitter_dirs {
            let query_path = dir.join("queries").join(lang_name).join(file_name);
            if let Ok(source) = fs::read_to_string(&query_path) {
                if let Ok(query) = Query::new(lang, &source) {
                    return Some(query);
                }
            }
        }
        None
    }
}

pub const LANG_MAPPINGS: &[(&[&str], &str)] = &[
    (&["ada"], "ada"),
    (&["apex"], "apex"),
    (&["bash", "shell", "zsh"], "bash"),
    (&["c"], "c"),
    (&["csharp", "c_sharp", "c#"], "c_sharp"),
    (&["capnp"], "capnp"),
    (&["clojure"], "clojure"),
    (&["cmake"], "cmake"),
    (&["c++", "cpp"], "cpp"),
    (&["css"], "css"),
    (&["cuda"], "cuda"),
    (&["cue"], "cue"),
    (&["d"], "d"),
    (&["dart"], "dart"),
    (&["devicetree", "dts"], "devicetree"),
    (&["diff"], "diff"),
    (&["elixir"], "elixir"),
    (&["elm"], "elm"),
    (&["enforce"], "enforce"),
    (&["fennel"], "fennel"),
    (&["fish"], "fish"),
    (&["fortran"], "fortran"),
    (&["gdscript"], "gdscript"),
    (&["glimmer"], "glimmer"),
    (&["glsl"], "glsl"),
    (&["go"], "go"),
    (&["graphql"], "graphql"),
    (&["groovy", "gradle"], "groovy"),
    (&["haskell"], "haskell"),
    (&["html"], "html"),
    (&["ini", "config", "configuration"], "ini"),
    (&["janet"], "janet_simple"),
    (&["java"], "java"),
    (&["javascript", "js"], "javascript"),
    (&["json"], "json"),
    (&["jsonnet"], "jsonnet"),
    (&["julia"], "julia"),
    (&["kdl"], "kdl"),
    (&["kotlin"], "kotlin"),
    (&["latex", "tex"], "latex"),
    (&["liquidsoap"], "liquidsoap"),
    (&["lua"], "lua"),
    (&["makefile", "make"], "make"),
    (&["markdown"], "markdown"),
    (&["matlab"], "matlab"),
    (&["nim"], "nim"),
    (&["nix"], "nix"),
    (&["nu", "nushell"], "nu"),
    (&["objdump"], "objdump"),
    (&["ocaml"], "ocaml"),
    (&["ocaml_interface"], "ocaml_interface"),
    (&["odin"], "odin"),
    (&["php"], "php"),
    (&["php_only"], "php_only"),
    (&["prisma"], "prisma"),
    (&["protobuf", "proto"], "proto"),
    (&["python"], "python"),
    (&["r"], "r"),
    (&["ruby"], "ruby"),
    (&["rust"], "rust"),
    (&["scala"], "scala"),
    (&["scss"], "scss"),
    (&["smali"], "smali"),
    (&["solidity", "sol"], "solidity"),
    (&["starlark", "bazel"], "starlark"),
    (&["svelte"], "svelte"),
    (&["swift"], "swift"),
    (&["systemverilog", "verilog"], "systemverilog"),
    (&["tact"], "tact"),
    (&["tcl"], "tcl"),
    (&["teal"], "teal"),
    (&["templ"], "templ"),
    (&["terraform", "tf"], "terraform"),
    (&["toml"], "toml"),
    (&["tsx"], "tsx"),
    (&["typescript", "ts"], "typescript"),
    (&["typoscript"], "typoscript"),
    (&["typst"], "typst"),
    (&["usd"], "usd"),
    (&["vhdl"], "vhdl"),
    (&["vim", "viml"], "vim"),
    (&["vue"], "vue"),
    (&["xml"], "xml"),
    (&["yaml"], "yaml"),
    (&["yang"], "yang"),
    (&["zig"], "zig"),
];
