{
  lib,
  writeShellApplication,
  context-grep,
  vimPlugins,
}:
writeShellApplication {
  name = "context-grep";
  runtimeEnv.CONTEXT_GREP_NVIM_PLUGIN_DIRS = "${context-grep.nvim-plugin-grammars}:${vimPlugins.nvim-treesitter-context}";
  text = ''
    exec ${lib.getExe context-grep.context-grep-rs} "$@"
  '';
}
