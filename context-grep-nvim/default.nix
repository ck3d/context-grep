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
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "context-grep-nvim";
  version = "0.1.0";

  src = lib.cleanSourceWith {
    src = ./.;
    filter =
      path: _type:
      !(lib.elem (baseNameOf path) [
        "default.nix"
        ".envrc"
      ]);
  };

  nativeBuildInputs = [ makeWrapper ];

  env.CONTEXT_GREP_NVIM_PLUGIN_DIRS = "${context-grep.nvim-plugin-grammars}:${vimPlugins.nvim-treesitter-context}";

  postFixup = ''
    wrapProgram $out/bin/context-grep-nvim \
      --set CONTEXT_GREP_NVIM_PLUGIN_DIRS "$CONTEXT_GREP_NVIM_PLUGIN_DIRS" \
      --prefix PATH : ${lib.makeBinPath [ neovim-unwrapped ]}
  '';

  passthru.devShell = mkShellNoCC {
    inherit (finalAttrs) env;
    packages = [
      neovim-unwrapped
    ];
    inputsFrom = builtins.attrValues finalAttrs.passthru.checks;
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
          inherit (finalAttrs.env) CONTEXT_GREP_NVIM_PLUGIN_DIRS;
          nativeBuildInputs = [ context-grep.test-harness ];
        }
        ''
          test-harness ${lib.getExe finalAttrs.finalPackage}
          touch $out
        '';
  };

  meta = {
    description = "Search for regex patterns within comments and return surrounding code context";
    mainProgram = "context-grep-nvim";
    inherit (neovim-unwrapped.meta) platforms;
  };
})
