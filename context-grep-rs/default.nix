{
  lib,
  pkg-config,
  tree-sitter,
  context-grep,
  vimPlugins,
  craneLib,
  runCommand,
}:
let
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.fileFilter (file: !file.hasExt "nix") ./.;
  };

  commonArgs = {
    inherit src;
    pname = "context-grep-rs-unwrapped";
    version = "0.1.0";
    nativeBuildInputs = [ pkg-config ];
    buildInputs = [ tree-sitter ];
  };

  CONTEXT_GREP_NVIM_PLUGIN_DIRS = "${context-grep.nvim-plugin-grammars}:${vimPlugins.nvim-treesitter-context}";

  cargoArtifacts = craneLib.buildDepsOnly commonArgs;

  pkg = craneLib.buildPackage (
    commonArgs
    // {
      inherit cargoArtifacts;

      passthru.devShell = craneLib.devShell {
        inherit CONTEXT_GREP_NVIM_PLUGIN_DIRS;
        inputsFrom = [ pkg.passthru.checks.test-harness ];
      };

      passthru.checks = {
        fmt = craneLib.cargoFmt {
          inherit src;
        };
        clippy = craneLib.cargoClippy (
          commonArgs
          // {
            inherit cargoArtifacts;
          }
        );
        test-harness =
          runCommand "context-grep-test-harness-check"
            {
              inherit CONTEXT_GREP_NVIM_PLUGIN_DIRS;
              nativeBuildInputs = [ context-grep.test-harness ];
            }
            ''
              test-harness ${lib.getExe pkg}
              touch $out
            '';
      };

      meta.mainProgram = "context-grep";
    }
  );
in
pkg
