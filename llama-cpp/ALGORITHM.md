# The tiled GEMM, in portable terms

This is the performance half. It is independent of the wave-width correctness work and can be
taken or left alone.

## Why the fallback is slow

When a device reports `has_simdgroup_mm == false` (no matrix cores — every AMD GPU Metal
supports), `ggml-metal-ops.cpp` skips the tiled path and calls `ggml_metal_op_mul_mat_mv`.
Its grid is:

```c
dispatch_threadgroups((ne01 + r0ptg - 1)/r0ptg, ne11, ne12*ne13, simd_width, nsg, 1);
//                      ^ over output rows      ^ one threadgroup PER OUTPUT COLUMN
```

One threadgroup owns **one column** of the output. To produce `ne11` columns, the weight
matrix is streamed `ne11` times. For a 4096×320 f32 projection at `ne11 = 4096` that is
~21 GB of weight traffic where ~5 MB plus the output write would do.

Measured on an RX 580: 6.05 s per UNet step, 24.6 s for a single VAE decode graph.

## The kernel

One threadgroup owns a `BM × BN` tile of the output and reads each operand tile once.

| parameter | value | why |
|---|---|---|
| `BM`, `BN` | 32, 32 | traffic scales as `ne11·ne01·K·(1/BM + 1/BN)` — square minimises it |
| `BK` | 64 | fewer barriers per K; 16 → 64 was worth 1.3% |
| threads | `(BM/2)·(BN/2) = 256` | **the critical choice** |
| per thread | 2×2 outputs in registers | 4 FMAs per 2 shared-memory loads |

Structure:

1. Cooperatively stage A (`BM×BK`) and B (`BK×BN`) into threadgroup memory, zero-padding
   the edges so the inner loop needs no bounds checks.
2. `threadgroup_barrier`.
3. Each thread accumulates its 2×2 block from shared memory.
4. `threadgroup_barrier`, advance K.

Total threadgroup memory: `(32·64 + 64·32)·4 = 16 KiB`.

## The measurement that matters

| tile | threads | 20-step SD 2.1 | verdict |
|---|---|---|---|
| 16×16, 1 out/thread | 256 | 89.1 s | baseline |
| **32×32, 2×2 out/thread** | **256** | **77.6 s** | **kept** |
| 16×32, 1 out/thread | 512 | 95.7 s | worse |
| 32×32, 1 out/thread | 1024 | 107.3 s | much worse |

The obvious move — a bigger tile at one output per thread — needs a 1024-thread
threadgroup and **loses 18%**. On this class of GPU only about two threadgroups remain
resident per compute unit at that size, so there is almost nothing in flight to hide memory
latency. Holding the same tile in registers keeps the crew at 256 and wins.

Run-to-run variance, measured by repeating an identical kernel that produced byte-identical
output: **~4%** (89.1, 89.6, 92.7 s). Any result inside that band is noise.

## Portability notes

- Operand types must be a template parameter pair, not a single one. Restricting the kernel
  to `src1 == f32` silently excludes every IM2COL convolution (f16 × f16), which on SD 2.1
  was 16% of the runtime and half of the UNet's convolutions. This was the single largest
  win of the whole effort, and it was invisible until the profiler showed where time went.
- Derive the thread count as `(BM/2)·(BN/2)` and the shared-memory size as
  `(BM·BK + BK·BN)·sizeof(float)`. Hand-written constants that assume `BM == BN` drift the
  moment a tile shape changes — that drift was a latent bug here before it was fixed.
- Output addressing must match the matvec path exactly:
  `dst_f32[im*ne0*ne1 + column*ne0 + row]`.
