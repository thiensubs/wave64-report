# The pattern in ggml's Metal backend (llama.cpp master, 2026-11-04)

Studied at `ggml-org/llama.cpp` @ `13ec8f614` before proposing anything.

## 1. The width is one hard-coded line

`ggml/src/ggml-metal/kernels/common.h:23`

```c
#define N_SIMDWIDTH 32 // assuming SIMD group size is 32
```

That macro is used **42 times across 14 kernels**. Every lane calculation,
threadgroup layout and per-round advance in the quantised path derives from it.
This is not a kernel bug that happens to affect AMD; it is a backend-wide
assumption with a comment admitting it.

## 2. The scaffolding for a real value already exists

Two facts make this cheap, and they are the strongest part of any proposal:

| Piece | Where | Today |
|---|---|---|
| The real SIMD width | `MTLComputePipelineState.threadExecutionWidth` | queried at pipeline creation, **only logged at debug level** (`ggml-metal-device.m:805`) |
| Per-device kernel defines | `MTLCompileOptions.preprocessorMacros` | already used; kernels are built from source at runtime |

There is no `simd_width` field in `ggml_metal_device_props` (it has
`has_simdgroup_reduction` and `has_simdgroup_mm`, nothing about width). So the
runtime knows the number and throws it away, then a header re-states it as 32.

## 3. What "handle wave64" therefore looks like in their architecture

Three stages, each independently reviewable:

1. **Plumbing (no behaviour change at 32).** Store the pipeline's
   `threadExecutionWidth` in the device props and pass `N_SIMDWIDTH=<width>` into
   the kernel compile macros instead of the fixed header value. On Apple Silicon
   the compiled kernels become byte-identical.
2. **Width-independent lane math.** Replace every `NQ`-as-lanes-per-block and
   `ib += NQ` in the quantised matvec with values derived from the block, and
   replace the `#if N_SIMDWIDTH == 32` guards around `fa_vec_*` with real
   fallbacks. At 32 every expression reduces to the current one.
3. **Performance (separate).** The tiled SIMT GEMM for quantised matvec.

Stage 1 is the ask. Stages 2–3 are patches that already exist, and stage 2 is the
one that fixes the white images.

## 4. Their own pattern for Metal fixes

Recent commits in the same area, from `git log -- ggml/src/ggml-metal`:

```
a194a75b7 metal : fix NORM/RMS_NORM for row lengths that leave a partial simdgroup (#26708)
aac810230 metal : fix idle threads in the remaining iq mul_mv kernels for ne00 < 1024 (#28692)
88ada91c1 metal : fix idle threads in mul_mv_iq3_xxs for ne00 < 1024 (#28086)
5bda51bfb metal : skip the empty half of the mul_mm_id token tile (#28301)
```

The shape is consistent:

- subject: `metal : <what is fixed> (#issue)`
- scope: one kernel family, one condition
- body: what the sizing/guard did, why it failed, what the fix computes instead
- verified by a named command or a before/after measurement

A "support 64-wide simdgroups" PR does not fit that shape. A "pass the real
simdgroup width into the kernel build" change does.

## 5. The bug this unblocks, still present in master

```
ggml/src/ggml-metal/kernels/mul_mv.metal
  231:  constexpr short NQ  = 16;
  259:  const short     ix  = (tiisg/(NW/NQ));      // 4 at NW=64, should be 2
  272:  for (int ib = ib0; ib < nb; ib += NQ) {     // advances 16, should be 32
```

At `NW == 64` half the weights are never read; infinities clip to white. No
assert fires. Apple Silicon (32) is unaffected.

## 6. How to frame the ask

Not: "add AMD support" (too broad, no owner).
But: *"the backend queries `threadExecutionWidth` and then hard-codes 32 in
`common.h`; would you take a change that passes the queried value into the kernel
compile, so width follows the device? Width 32 output is unchanged, and it is the
prerequisite for the quantised matvec fix that produces white images on RDNA."*

That is one decision for a maintainer, with a clear blast radius, and it matches
the style of their existing Metal commits.
