# What the patch changes, in four ideas

## 1. Lanes per block come from the block, not from the wave

```c
constexpr short NLB = QK4_0/NQ;   // 32 quants / 16 per lane = 2 lanes per block
constexpr short NBL = NW/NLB;     // blocks per round: 16 at 32 lanes, 32 at 64
```

The old code read `NQ` (quantised values per lane) as if it also meant *lanes per
block*. At a simdgroup width of 64 that addresses half the data it should.

## 2. Advance by the blocks actually covered per round

```c
for (int ib = ib0; ib < nb; ib += NBL) { ... yb += QK4_0*NBL; }
```

The old increment assumed 32 lanes, so the second half of every round was
skipped. This is the defect that produced infinities and then white images.

## 3. q8_0 has the same defect

`NQ` does the same double duty there; fixed identically.

At 32 lanes, all three expressions collapse to the current ones — that is the
property that makes the patch safe for Apple Silicon.

## 4. The performance half: a tiled SIMT GEMM

Without a matrix unit, the fallback re-reads the whole weight table once per
output column. The patch stages the weight block in threadgroup memory,
computes a tile of output columns from that one load, and pads the threadgroup
array to avoid bank conflicts. The report measures pp512 at 110 → 198 t/s on the
RX 580 with this change.

## What is *not* here

- No model-format or loader changes.
- The group-norm fix is a separate patch: `0002-group-norm-inplace.patch`.

Numbers and the reasoning behind them live in the report, not in this file.
