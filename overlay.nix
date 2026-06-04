final: prev: {
  context-grep = {
    context-grep = final.callPackage ./package.nix { };
    default = final.context-grep.context-grep;
  };
}
