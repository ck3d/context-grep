{
  lib,
  stdenvNoCC,
  neovim-unwrapped,
  makeWrapper,
  context-grep,
  vimPlugins,
  mkShellNoCC,
  stylua,
  runCommand,
}:
let
  CONTEXT_GREP_NVIM_PLUGIN_DIRS = "${context-grep.nvim-plugin-grammars}:${vimPlugins.nvim-treesitter-context}";

  pkg = stdenvNoCC.mkDerivation {
    pname = "context-grep-nvim";
    version = "0.1.0";

    src = lib.fileset.toSource {
      root = ./.;
      fileset = lib.fileset.fileFilter (file: !file.hasExt "nix") ./.;
    };

    nativeBuildInputs = [ makeWrapper ];

    inherit CONTEXT_GREP_NVIM_PLUGIN_DIRS;

    installPhase = ''
      mkdir -p $out/bin
      cp context-grep-nvim $out/bin/context-grep-nvim
      cp context-grep-nvim.lua $out/bin/context-grep-nvim.lua
      chmod +x $out/bin/context-grep-nvim
    '';

    postFixup = ''
      wrapProgram $out/bin/context-grep-nvim \
        --set CONTEXT_GREP_NVIM_PLUGIN_DIRS "$CONTEXT_GREP_NVIM_PLUGIN_DIRS" \
        --prefix PATH : ${lib.makeBinPath [ neovim-unwrapped ]}
    '';

    passthru.devShell = mkShellNoCC {
      inherit CONTEXT_GREP_NVIM_PLUGIN_DIRS;
      packages = [
        context-grep.test-harness
        neovim-unwrapped
      ];
      inputsFrom = [
        pkg.checks.fmt
      ];
    };

    passthru.checks = {
      fmt =
        runCommand "context-grep-nvim-stylua-check"
          {
            nativeBuildInputs = [ stylua ];
          }
          ''
            stylua --config-path ${./.stylua.toml} --check ${./context-grep-nvim.lua}
            touch $out
          '';
      test-harness =
        runCommand "context-grep-nvim-test-harness-check"
          {
            inherit CONTEXT_GREP_NVIM_PLUGIN_DIRS;
          }
          ''
            ${lib.getExe context-grep.test-harness} ${lib.getExe pkg}
            touch $out
          '';
    };

    meta = {
      description = "Search for regex patterns within comments and return surrounding code context";
      mainProgram = "context-grep-nvim";
      inherit (neovim-unwrapped.meta) platforms;
    };
  };
in
pkg
