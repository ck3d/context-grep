{
  runCommand,
  hyperfine,
  context-grep,
}:
let
  sampleDir = "${context-grep.test-harness}/share/test-harness";
in
runCommand "context-grep-benchmark"
  {
    nativeBuildInputs = [
      hyperfine
      context-grep.context-grep-nvim
      context-grep.context-grep-rs-wrapped
    ];
  }
  ''
    hyperfine --warmup 3 \
      --export-markdown "$out" \
      "context-grep-nvim 'TODO' ${sampleDir}/*" \
      "context-grep 'TODO' ${sampleDir}/*"
  ''
