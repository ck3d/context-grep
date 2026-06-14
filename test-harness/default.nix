{
  lib,
  stdenv,
  makeWrapper,
  bashNonInteractive,
  jaq,
  yajsv,
  shellcheck,
  context-grep,
  mkShellNoCC,
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

  buildInputs = [
    bashNonInteractive
  ];

  doCheck = true;

  env = {
    SCHEMA_FILE = toString context-grep.context-grep-schema;
  };

  nativeBuildInputs = [
    makeWrapper
    shellcheck
  ]
  ++ runtimeDeps;

  passthru.devShell = mkShellNoCC {
    inherit (finalAttrs) env;
    packages = [ context-grep.context-grep-rs-wrapped ];
    inputsFrom = [ finalAttrs ];
  };

  postFixup = ''
    wrapProgram $out/bin/test-harness \
      --set SAMPLE_DIR "$out/share/test-harness" \
      --set SCHEMA_FILE "$SCHEMA_FILE" \
      --prefix PATH : ${lib.makeBinPath runtimeDeps}
  '';

  meta.mainProgram = "test-harness";
})
