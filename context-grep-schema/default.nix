{
  lib,
  context-grep,
  quicktype,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation {
  name = "context-grep.schema.json";
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

  doCheck = true;
}
