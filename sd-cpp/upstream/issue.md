## Environment

- macOS 15.7.7, Intel MacBookPro13,3, AMD Radeon RX 580 8 GB over Thunderbolt
- `stable-diffusion.cpp` @ `5356982`, `ggml` submodule @ `d49c49e`
- SD 2.1 (`v2-1_512-ema-pruned.safetensors`), Metal backend

## Symptom

Every image comes out pure white: standard deviation 0.00 over the whole output,
for every prompt and every seed. The same build works on Apple Silicon. On this
GPU the Metal simdgroup width is 64; Apple Silicon runs at 32.

## Root cause — four defects, all only visible at width 64

1. `mul_mv.metal` reads `NQ` as "lanes per block", but `NQ` is "quantised values
   per lane" (16 for `q4_0`). Lanes per block is `QK4_0/NQ` = 2, independent of
   the wave width.
2. The loop advance uses `NQ` instead of the blocks covered per round
   (`NW/NLB` = 16 at 32 lanes, 32 at 64), so the second half of every round is
   skipped.
3. `q8_0` carries the identical defect.
4. `fa_vec_*` is wrapped in `#if N_SIMDWIDTH == 32`, so flash attention compiles
   out entirely at width 64.

At width 32 every expression reduces to the current one, so Apple Silicon cannot
regress — that property is what makes the change reviewable.

## Evidence

- Conformance matrix 1347/1347 across the dtypes SD 2.1 executes.
- Same card: 16.26 s/it → 3.88 s/it at 20 steps (4.19×) with the follow-up tiled
  SIMT GEMM for the quantised matvec.
- Unpack of the tiled path is bit-exact against the reference.

Full write-up, including the four failures in order and the history of this bug
across llama.cpp #19563, #19601 and MoltenVK #2756:

https://app8601830087.tgcloud.ai/r/rx580-white-images-fix/

## Patch

Two patches against the commits above, both apply with `git apply --check`:

https://github.com/thiensubs/wave64-report/tree/main/sd-cpp

The kernel changes live in `ggml/`, so a PR here would need the ggml change
first and then a submodule bump. I am happy to split it that way, or to take the
kernel work to the right repository if that is preferred.

## Question

Is this in scope for the project? If yes, what would you want in the PR — the
correctness fix alone, or the tiled GEMM as a separate change?

---

AI assistance was used to draft this text and the write-up; I reviewed the
patches and can explain every line.
