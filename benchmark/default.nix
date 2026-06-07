{
  runCommand,
  hyperfine,
  context-grep,
}:
runCommand "context-grep-benchmark"
  {
    nativeBuildInputs = [
      hyperfine
      context-grep.context-grep-nvim
      context-grep.context-grep-rs-wrapped
    ];
  }
  ''
    SAMPLE_DIR="${context-grep.test-harness}/share/test-harness"

    hyperfine --warmup 3 \
      --export-markdown "$out" \
      "context-grep-nvim 'TODO' $SAMPLE_DIR/*" \
      "context-grep 'TODO' $SAMPLE_DIR/*"
  ''
