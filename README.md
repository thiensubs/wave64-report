# wave64-report

**Read it:** [app8601830087.tgcloud.ai/r/rx580-white-images-fix](https://app8601830087.tgcloud.ai/r/rx580-white-images-fix/)

A graphics card that was never supposed to run this software, a bug that turned every image pure
white, and the four kernel bugs that fixed it. Stable Diffusion 2.1 on an AMD RX 580 through
Metal, **4.19x faster** than where it started.

Chapter 1 is this page. Chapter 2, on 64-lane hardware in llama.cpp, is in progress in
[`llama-cpp/`](llama-cpp/).

## Ko-fi donations

<a href="https://ko-fi.com/thiensubs"><img src="https://storage.ko-fi.com/cdn/brandasset/kofi_button_red.png" alt="Keep the AI cooking on Ko-fi" width="220"></a>

**Keep the AI cooking** — [ko-fi.com/thiensubs](https://ko-fi.com/thiensubs)

If this saved you a week, that is what the button is for.

## Contents

| Part | What it covers |
|---|---|
| 1 - The win | The outcome in numbers, the energy chart, the image gallery |
| 2 - The problem | Why a GPU wave is a rowing boat; 32 vs 64 lanes; who is affected |
| 3 - How it happened | Four bugs in the order they were found, the matrix, the tiling diagrams |
| 4 - Chapter 2 | What upstream says, the three-hunk patch, the policy that shapes it |
| Appendix | Paths, reproduce commands, numbers, traps, and every known failure |

Open `index.html` in any browser. No build step, no dependencies.

## Files

```
index.html                             the report (self-contained)
VERSION                                current version (1.2)
CHANGELOG.md                           what each frozen snapshot contains
LICENSE                                MIT
assets/                                six WebP images, the numeral, the 1200x630 card
llama-cpp/README.md                    what upstream says, and what the fix changes
llama-cpp/NOTES.md                     measurements and commands for the human to write up
llama-cpp/0001-mul-mv-lanes-per-block.patch   the diff, three hunks
llama-cpp/ALGORITHM.md                 the tiled GEMM design, portable notes
```

There is deliberately **no PR draft**. llama.cpp's `AGENTS.md` prohibits AI-written PR
descriptions, commit messages and reviewer responses, and automated submissions can get a
contributor banned. The submission has to come from the person who did the work.

## What is claimed, and what is not

- **Measured on hardware:** Parts 1 and 3. Numbers from `sd-rx580/evidence/bench.csv`,
  reproducible with `sd-rx580/tools/bench.sh`.
- **Measured on hardware, same source shape:** the q4/q5 lane defect (43 failures before, 0 after).
- **Observed on a stock build:** llama.cpp refuses q4_0 on this card — every case reports
  `not supported [MTL0]`. That is the workaround, not the bug.
- **Not done:** the whitelist-removed run on a stock checkout. That is Chapter 2's remaining job,
  and the report says so in three places.
- **Not attempted:** MI300, RDNA, or any second AMD Metal device. One card was available.

## Provenance

RX 580 (Polaris, gfx803), macOS, patched `ggml` Metal backend, Stable Diffusion 2.1
`v2-1_512-ema-pruned`, 512x512, 20 steps, euler-a, cfg 7.0.
Engineering board: `sd-rx580/docs/wave64-board.md`.

## Version

**v1.2**, 2026-11-04. MIT licensed. Corrections ship as a new version with a `CHANGELOG.md` entry,
never as a silent edit to a URL someone may have cited.
