{
  lib,
  stdenv,
  mkShellNoCC,
  makeWrapper,
  jaq,
  yajsv,
  shellcheck,
  runCommand,
  context-grep,
}:
let
  runtimeDeps = [
    jaq
    yajsv
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "context-grep-test-harness";
  version = "0.1.0";
  strictDeps = true;

  src = lib.cleanSourceWith {
    src = ./.;
    filter =
      path: _type:
      !(lib.elem (baseNameOf path) [
        "default.nix"
        ".envrc"
      ]);
  };

  env = {
    SCHEMA_FILE = toString context-grep.context-grep-schema;
  };

  nativeBuildInputs = [ makeWrapper ] ++ runtimeDeps;

  postFixup = ''
    wrapProgram $out/bin/test-harness \
      --set SAMPLE_DIR "$out/share/test-harness" \
      --set SCHEMA_FILE "$SCHEMA_FILE" \
      --prefix PATH : ${lib.makeBinPath runtimeDeps}
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
    inputsFrom = [
      finalAttrs
    ]
    ++ builtins.attrValues finalAttrs.passthru.tests;
    inherit (finalAttrs) env;
  };

  meta.mainProgram = "test-harness";
})
