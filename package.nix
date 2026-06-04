{
  lib,
  runCommand,
  neovim-unwrapped,
  makeWrapper,
  writeText,
  vimPlugins,
  supportedLanguages ? import ./supported-languages.nix,
}:
let
  initLua = writeText "init.lua" ''
    ${lib.concatMapStrings (lang: ''
      vim.treesitter.language.add("${lang}", { path = "${
        vimPlugins.nvim-treesitter.builtGrammars.${lang}
      }/parser" })
    '') supportedLanguages}
    vim.opt.rtp:append("${vimPlugins.nvim-treesitter-context}")
  '';
in
runCommand "context-grep"
  {
    nativeBuildInputs = [ makeWrapper ];
    meta = {
      description = "Search for regex patterns within comments and return surrounding code context";
      mainProgram = "context-grep";
      inherit (neovim-unwrapped.meta) platforms;
    };
  }
  ''
    makeWrapper ${neovim-unwrapped}/bin/nvim $out/bin/context-grep \
      --set NVIM_LOG_FILE /dev/null \
      --add-flags "--headless" \
      --add-flags "--clean" \
      --add-flags "-n" \
      --add-flags "-R" \
      --add-flags "-u" \
      --add-flags "${initLua}" \
      --add-flags "-l" \
      --add-flags "${./context-grep.lua}"
  ''
