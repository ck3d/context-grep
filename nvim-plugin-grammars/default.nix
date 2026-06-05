{
  symlinkJoin,
  vimPlugins,
  supportedLanguages ? import ./supported-languages.nix,
}:
let
  inherit (vimPlugins.nvim-treesitter) queries parsers;

  selectFrom =
    attrs:
    builtins.concatMap (lang: if attrs ? ${lang} then [ attrs.${lang} ] else [ ]) supportedLanguages;
in
symlinkJoin {
  name = "context-grep-grammars";
  paths = selectFrom queries ++ selectFrom parsers;
}
