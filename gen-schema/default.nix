{
  lib,
  context-grep,
  quicktype,
  stdenvNoCC,
  runCommand,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "gen-schema.json";
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

  nativeBuildInputs = [
    quicktype
    context-grep.context-grep-rs-wrapped
  ];

  passthru.tests = {
    diff = runCommand "gen-schema.diff" { } ''
      diff -u ${../schema.json} ${finalAttrs.finalPackage}
      touch $out
    '';
  };
})
