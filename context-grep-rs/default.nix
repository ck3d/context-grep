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
  commonArgs = {
    strictDeps = true;
    src = lib.cleanSourceWith {
      src = ./.;
      filter =
        path: _type:
        !(lib.elem (baseNameOf path) [
          "default.nix"
          ".envrc"
          ".gitignore"
        ]);
    };

    nativeBuildInputs = [ pkg-config ];
    buildInputs = [ tree-sitter ];
  };

  env.CONTEXT_GREP_NVIM_PLUGIN_DIRS = "${context-grep.nvim-plugin-grammars}:${vimPlugins.nvim-treesitter-context}";

  cargoArtifacts = craneLib.buildDepsOnly commonArgs;

  pkg = craneLib.buildPackage (
    commonArgs
    // {
      inherit cargoArtifacts;

      passthru.devShell = craneLib.devShell {
        inherit env;
        inputsFrom = [ pkg.passthru.tests.test-harness ];
      };

      passthru.tests = {
        fmt = craneLib.cargoFmt {
          inherit (commonArgs) src;
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
              inherit env;
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
