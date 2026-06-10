{
  lib,
  stdenv,
  mkShellNoCC,
  makeWrapper,
  jaq,
  shellcheck,
  runCommand,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "context-grep-test-harness";
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

  postFixup = ''
    wrapProgram $out/bin/test-harness \
      --set SAMPLE_DIR "$out/share/test-harness" \
      --prefix PATH : ${lib.makeBinPath [ jaq ]}
  '';

  passthru.tests = {
    shellcheck =
      runCommand "test-harness-shellcheck"
        {
          nativeBuildInputs = [ shellcheck ];
        }
        ''
          shellcheck ${./test-harness}
          touch $out
        '';
  };

  passthru.devShell = mkShellNoCC {
    inputsFrom = [ finalAttrs.passthru.tests.shellcheck ];
    packages = [
      jaq
    ];
  };

  meta.mainProgram = "test-harness";
})
