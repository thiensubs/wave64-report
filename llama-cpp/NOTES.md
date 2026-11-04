# Facts for the human, not a PR draft

This file exists because llama.cpp prohibits AI-written PR descriptions. Use it as raw
material - measurements, file locations, commands - and write the submission in your own
words, from your own understanding.

## The defect

File: `ggml/src/ggml-metal/kernels/mul_mv.metal`, function `mul_vec_q_n_f32_impl`
(serves q4_0, q4_1, q5_0, q5_1).

```
const short ix = (tiisg/(NW/NQ));
const short il = (tiisg%(NW/NQ))*8;
```

`NW` is `N_SIMDWIDTH`, which `ggml-metal-device.m` sets to the device's real width. At 64,
`NW/NQ` is 4, so `il` takes 0, 8, 16, 24. `block_q_n_dot_y` for q4 reads
`(uint16_t *)qb + 1 + il/2` and consumes four uint16 slots; a block holds slots 1-8. So
`il = 16` starts at slot 9 and `il = 24` is further out.

## The fix

```
constexpr short NLB = QK4_0/NQ;   // lanes per block = 2
constexpr short NBL = NW/NLB;     // blocks per round: 16 at NW=32, 32 at NW=64
const short ix = tiisg/NLB;
const short il = (tiisg%NLB)*8;
```

with the loop stride and the `yb` advance using `NBL`.

At `NW == 32`: `NLB == 2`, `NBL == 16 == NQ`, so every expression is numerically identical
to today. That is the review argument: no behaviour change on Apple hardware.

## Measured on an RX 580 (Polaris, gfx803, 64-lane), in a fork

| format | before | after |
|---|---|---|
| q4_0 | 43 failures | 0 |
| q5_0 | 56 failures | 0 |
| q5_1 | 49 failures | 0 |
| q8_0 | 39 failures | 0 |

The q8_0 case was the same defect and upstream already has it right there, using the NLB
idiom. That precedent is the strongest argument that this is the intended pattern.

## What to run

```
export GGML_METAL_PATH_RESOURCES=$PWD/ggml/src/ggml-metal
./build/bin/test-backend-ops -b MTL0 -o MUL_MAT -p type_a=q4_0
```

Three traps, each of which cost time here:

- Without `GGML_METAL_PATH_RESOURCES` the backend compiles `build/bin/kernels`, a build-time
  copy. Kernel edits then do nothing and you will chase a phantom.
- `-p` is not a regex over the whole params string. It splits on commas into `key=value`
  pairs, so `bs=[1,1]` cannot be expressed. Filter in a script instead.
- `-p 'type_a=q4_0'` on a stock build prints `not supported` for every case, because of the
  whitelist. Remove the four `case` labels and the comment first, or you will measure
  nothing.

## What is still unproven

The whitelist-removed run on a stock checkout. Everything above was measured in a fork that
also enables simdgroup reduction on non-Apple GPUs, which upstream reports as false. Those
are separate changes and should be described separately.

## Numbers upstream already published in the comment

```
0/121, 0/99, 0/63, 0/56 on MUL_MAT     // q4_0, q4_1, q5_0, q5_1
```

If the fix works, those become 121/121, 99/99, 63/63, 56/56. Reproduce those exact counts,
not your own filtered subset, or the comparison will not line up.
