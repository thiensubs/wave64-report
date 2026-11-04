# Upstream issue — facts, not a finished post

llama.cpp's CONTRIBUTING forbids AI-written issue and PR text, so this file is
**source material**: measurements, paths and links to turn into your own words.
Do not paste it as-is.

## Where

`ggml-org/llama.cpp` — the home of `ggml/src/ggml-metal/`.
`leejet/ggml` points there for core changes, and `stable-diffusion.cpp` only
carries a submodule pointer, so neither can take the patch directly.

## What breaks

Metal on AMD RDNA (RX 580, simdgroup width 64) produces **pure white images**.
The port assumes 32-wide simdgroups in the quantised matvec path:

- `NQ` is read as "lanes per block", but it is "quantised values per lane";
  at width 64 the kernel addresses half the data it should.
- The loop advance uses `NQ` instead of the blocks covered per round, so the
  second half of every round is skipped.
- `q8_0` has the identical defect.
- `fa_vec_*` is guarded by `#if N_SIMDWIDTH == 32`, so flash attention compiles
  out entirely at width 64.
- `group_norm` feeds `mul_inplace`/`add_inplace` on tensors the Metal path can
  alias; out-of-place ops fix it.

At width 32 every expression reduced to the current one, so Apple Silicon
cannot regress — that is the property that makes this reviewable.

## Evidence

- 4.19× speedup on the same card, measured: 16.26 s/it → 3.88 s/it at 20 steps.
- Conformance matrix 1347/1347 across the dtypes SD 2.1 executes.
- Bit-exact unpack test for the tiled GEMM.
- pp512 110 → 198 t/s after the tiled SIMT GEMM.

Full write-up with graphs, failures and the history of the bug across
llama.cpp #19563, #19601 and MoltenVK #2756:

- report: https://app8601830087.tgcloud.ai/r/rx580-white-images-fix/
- code + patches: https://app8601830087.tgcloud.ai/r/rx580-white-images-fix/sd-cpp/
- repo: wave64-report (`sd-cpp/` in that repository)

## Before posting

1. Strip the 12 instrumentation lines listed in `sd-cpp/` notes — `fprintf(stderr,
   …)`, `getenv("GGML_METAL_GPU_TIME")` and `ggml_backend_sched_dump_splits`
   cannot go upstream.
2. llama.cpp wants an issue first for a feature, and a regression test for a fix.
3. New contributors are limited to one open PR.
4. Disclose AI assistance in the post, as the policy requires.
