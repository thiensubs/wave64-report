## Summary

`ggml`'s Metal quantised matvec kernels assume a **32-wide simdgroup** in their
indexing. On RDNA1 (simdgroup width 64) they address half the data they should,
the arithmetic produces infinities, and the encoder clips them to white — **no
assert, no crash, no error**. The same build is correct on every Apple Silicon
Mac (width 32) and silently wrong on this GPU (width 64).

The fix is not a special case: derive *lanes per block* from the block, then the
kernel is width-independent, and at width 32 every expression reduces to the
current one.

## Why it is not a cosmetic bug

```c
constexpr short NQ  = 16;          // quantised values per lane — NOT lanes per block
const short     ix  = tiisg/NQ;    // wrong at width 64
for (int ib = ib0; ib < nb; ib += NQ) { ... }   // skips half of every round
```

`NQ` was doing two jobs: values per lane *and* lanes per block. Those are only
equal when `NW == 32`. At 64 the kernel reads half the weights and advances by
half the blocks.

## Scope — the same assumption appears in several kernels

- `mul_mv.metal`: `q4_0`, `q5_*`, `q8_0` and the `_K` variants
- `fa_vec_*`: guarded by `#if N_SIMDWIDTH == 32`, so flash attention compiles out
  entirely at width 64
- `norm.metal`, `ssm.metal`: same width assumption in the lane split
- `src/core/ggml_extend.cpp`: `group_norm` feeds `mul_inplace`/`add_inplace` on
  tensors the Metal path can alias

## This has been reported for three years, in five projects

| When | Where | Form |
|---|---|---|
| Sep 2023 | llama.cpp #3000 | "AMD GPU using mul_mm in metal", closed as stale |
| Jun 2024 | ollama #5071 | the same fault, reported from the application layer |
| Feb 2026 | llama.cpp #19563 | "garbage output on AMD discrete GPUs" |
| Feb 2026 | llama.cpp #19601 | concurrency on non-UMA + `simd_max(half)` sign bug |
| Jun 2026 | MoltenVK #2756 | shuffle ops broken on RDNA by the same 64-wide assumption |

Each was treated as an isolated hardware mystery. It is one named defect:
**width-dependent lane indexing in the quantised matvec.**

## Reproducer and numbers (RX 580, SD 2.1)

- Every image pure white, standard deviation 0.00, every prompt and seed.
- After the fix: conformance matrix 1347/1347 across the dtypes SD 2.1 executes.
- 16.26 s/it → 3.88 s/it at 20 steps (4.19×) with the follow-up tiled SIMT GEMM.
- Unpack of the tiled path is bit-exact against the reference.

Full write-up, with the four failures in order and the trail above:

https://app8601830087.tgcloud.ai/r/rx580-white-images-fix/

## Patch

Two patches, both pass `git apply --check` at the commits below:

- `stable-diffusion.cpp` @ `5356982`, `ggml` @ `d49c49e`
- https://github.com/thiensubs/wave64-report/tree/main/sd-cpp

The kernel changes live in `ggml/`, so a PR here needs the ggml change first and
then a submodule bump. I am happy to split it that way, or to take the kernel
work to `ggml` directly — whichever you prefer.

## Question

Is this in scope, and how would you like it split: the width-independence fix
alone, or the tiled GEMM as a separate change?

---

AI assistance was used to draft this text and the write-up; I reviewed the
patches and can explain every line.
