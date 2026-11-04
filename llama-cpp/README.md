# Part 4 - the llama.cpp contribution

Status: **not submitted. Not to be submitted by an agent.**

## What upstream actually says

`ggml/src/ggml-metal/ggml-metal-device.m`, in `ggml_metal_supports_mul_mat_wide`:

```
// q4_0/q4_1/q5_0/q5_1 still route through mul_mv_ext, which is not yet correct at 64
// lanes (0/121, 0/99, 0/63, 0/56 on MUL_MAT) even with nypsg and the dispatch width
// fixed - keep them on the CPU path until that is resolved.
```

So the bug is known, measured by someone else, and routed around: those four formats are
refused on 64-lane devices and fall back to the CPU. Verified on this machine with a stock
build:

```
$ ./build/bin/test-backend-ops -b MTL0 -o MUL_MAT -p type_a=q4_0
  MUL_MAT(type_a=q4_0,type_b=f32,m=576,n=512,k=576,...): not supported [MTL0]
  0/0 tests passed
```

Every case reports `not supported`. The failing kernel never runs, so there is nothing to
fail. That is why "stock llama.cpp produces garbage here" and "the q4 kernel is wrong here"
are different claims - the first is about the rest of the port, the second about a kernel
upstream deliberately does not reach.

## What the fix changes

`mul_vec_q_n_f32_impl` derives its lane split from the wave width. On a 64-lane device that
produces `il` of 0, 8, 16, 24, but a 4-bit block only has room for 0 and 8. Deriving the
split from the block instead - `NLB = QK4_0/NQ`, `NBL = NW/NLB` - is identical at width 32
and correct at 64.

Measured in the fork on this card: q4_0 43 failures before, 0 after; q5_0 56/0; q5_1 49/0.

What is **not** yet done: the run with the whitelist removed and the patch applied, on a
stock build, before and after. That is the only thing that converts `0/121` into `121/121`
by measurement.

## The policy that shapes this folder

llama.cpp's `AGENTS.md` says, in its own words:

- AI-written PR descriptions, commit messages and reviewer responses are **prohibited**, and
  result in immediate PR closure.
- Automated commits and PR submissions may result in a contributor ban.
- A fully autonomous agent operating without human oversight must not contribute at all.
- Comments must be ASCII, one or two lines, plain simplified English.

An earlier draft in this folder (`PR.md`) was an AI-written PR description. It was exactly
the prohibited artifact, so it has been deleted. `NOTES.md` replaces it with facts only.

Anything submitted from here is written, understood and owned by the human contributor.

## What remains, in order

1. Apply the patch to a stock checkout, remove the comment and the four `case` labels from
   the whitelist, rebuild.
2. Run `test-backend-ops` for q4_0, q4_1, q5_0, q5_1. Capture before and after.
3. Confirm the 32-lane path is byte-identical, which is the property that makes the patch
   reviewable in the first place.
4. Write the PR yourself, with the numbers you measured.
