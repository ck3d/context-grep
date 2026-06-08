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

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.fileFilter (file: !file.hasExt "nix") ./.;
  };

  nativeBuildInputs = [ makeWrapper ];

  postFixup = ''
    wrapProgram $out/bin/test-harness \
      --set SAMPLE_DIR "$out/share/test-harness" \
      --prefix PATH : ${lib.makeBinPath [ jaq ]}
  '';

  passthru.checks = {
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
    inputsFrom = [ finalAttrs.passthru.checks.shellcheck ];
    packages = [
      jaq
    ];
  };

  meta.mainProgram = "test-harness";
})
