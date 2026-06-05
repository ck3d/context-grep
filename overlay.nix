final: prev:
let
  inherit (final) callPackage;
in
{
  context-grep = {
    context-grep-nvim = callPackage ./context-grep-nvim { };
    context-grep-rs = callPackage ./context-grep-rs { };
    context-grep-rs-wrapped = callPackage ./context-grep-rs/wrapper.nix { };
    nvim-plugin-grammars = callPackage ./nvim-plugin-grammars { };
    test-harness = callPackage ./test-harness { };
    default = final.context-grep.context-grep-rs-wrapped;
  };
}
