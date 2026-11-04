# Upstream contribution — the root repo is `ggml-org/llama.cpp`

`ggml` is developed inside llama.cpp. `leejet/ggml` says so in its CONTRIBUTING,
and `stable-diffusion.cpp` only pins a submodule, so the kernel fix has to start
at the root.

## Where the bug is live, confirmed today

llama.cpp `master` @ `13ec8f614cfef964fe97bbf872bc436dbc484a1f`:

```
ggml/src/ggml-metal/kernels/mul_mv.metal
  231:  constexpr short NQ = 16;
  259:  const short ix = (tiisg/(NW/NQ));
  260:  const short il = (tiisg%(NW/NQ))*8;
  272:  for (int ib = ib0; ib < nb; ib += NQ) {
  526:  constexpr short NQ = 8;
  553:  const short ix = tiisg/(NW/NQ);
  554:  const short il = tiisg%(NW/NQ);
```

At `NW == 32` this is correct. At `NW == 64` — every RDNA1/RDNA2 GPU under
Metal — `NW/NQ` becomes 4 instead of 2, and `ib += NQ` advances by 16 instead of
32 blocks. Half the weights are never read; the result clips to white.

Useful check before posting: those exact line numbers may drift. Search for
`tiisg/(NW/NQ)` and `ib += NQ` instead of trusting the numbers.

## Duplicate check (2026-11-04)

Searched llama.cpp issues for `simdgroup width 64`, `AMD metal garbage`,
`RDNA metal` — no matching issue. Related history is in the trail below.

## The trail

| When | Where | Form |
|---|---|---|
| Sep 2023 | llama.cpp #3000 | "AMD GPU using mul_mm in metal", auto-closed as stale |
| Jun 2024 | ollama #5071 | same fault, reported from the application layer |
| Feb 2026 | llama.cpp #19563 | "garbage output on AMD discrete GPUs" |
| Feb 2026 | llama.cpp #19601 | non-UMA concurrency + `simd_max(half)` sign |
| Jun 2026 | MoltenVK #2756 | shuffle ops broken on RDNA by the same 64-wide assumption |

## The invariant to argue for

> Lanes per block = quantised values per block ÷ values per lane.

Derive it from the block, never from the wave width. At `NW == 32` the
expression collapses to the current one, which is the reviewability argument.

## Policy, read before posting

llama.cpp's CONTRIBUTING contains:

> It is strictly prohibited to use AI to write your posts for you (bug reports,
> feature requests, pull request descriptions, …).

So the issue text must be yours. This file is source material: measurements,
paths, line numbers, links. Do not paste it verbatim.

Also required there: an issue before a feature, a regression test for a fix,
and one open PR maximum for a new contributor.

## Evidence to cite

- RX 580: every image pure white, std 0.00, any prompt and seed; correct on
  Apple Silicon (width 32).
- After the fix: 1347/1347 conformance, bit-exact unpack.
- 16.26 s/it → 3.88 s/it at 20 steps (4.19×) with the tiled SIMT GEMM.
- Report: https://app8601830087.tgcloud.ai/r/rx580-white-images-fix/
- Patches: https://github.com/thiensubs/wave64-report/tree/main/sd-cpp
- Symptom report already open in sd.cpp: leejet/stable-diffusion.cpp#2271
