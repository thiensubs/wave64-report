# Changelog

Versions are frozen snapshots, not a work log. Once a chapter is published under a slug, its
content stops changing — corrections go in a new version with a note here, never silently.

## v1.2 — 2026-11-04

Packaging for GitHub. No change to any measured claim.

- Live URL known, so the placeholders are gone: `<link rel="canonical">`, `og:url` and
  `og:image` are absolute and point at
  `https://app8601830087.tgcloud.ai/r/rx580-white-images-fix/`. All four resolve 200.
- The tgcloud copy is declared canonical. A GitHub Pages mirror of the same file would
  otherwise compete with it in search.
- Added `LICENSE` (MIT), `.gitignore`, and `.github/workflows/pages.yml` so Pages publishes
  this folder on push with nothing to build.
- README gains the read-it link and the exact commands to create and publish the repository.

## v1.1 — 2026-11-04

Correction, not a feature. Reading llama.cpp's own source and running its stock test binary
changed what Part 4 is allowed to claim.

**Corrected**

- Part 4 implied the q4/q5 lane defect was unknown upstream. It is not. `ggml_metal_supports_mul_mat_wide`
  carries a comment naming the formats and the counts (`0/121, 0/99, 0/63, 0/56 on MUL_MAT`) and
  refuses them on 64-lane devices so they fall back to the CPU. Verified here: on a stock build
  every q4_0 case reports `not supported [MTL0]` and zero tests execute.
- `llama-cpp/PR.md` deleted. llama.cpp's `AGENTS.md` prohibits AI-written PR descriptions,
  commit messages and reviewer responses, and automated submissions can get a contributor
  banned. That file was the one artifact guaranteed to sink the contribution. Replaced by
  `llama-cpp/NOTES.md`, which holds measurements and commands only.
- "Unexercised" was the wrong word. The kernel is not exercised because upstream declines to
  exercise it - a deliberate workaround, not an oversight.

**Unchanged**

Every measured number. The speed, energy and matrix results from v1.0 stand as published.

**Readability pass, same version**

- Part 4 rewritten in plain language. "Whitelist", "latent", "index past the end of the block",
  "stage operands in threadgroup memory", "three hunks" and "test plan ready to paste into a PR"
  were all replaced with the box-of-numbers and recipe analogies used in Parts 1-3.
- Code blocks stay as evidence; the prose around them now explains in words a non-engineer can
  follow. The appendix remains deliberately technical.



First published version of **Chapter 1**. Frozen.

**What it contains**

- Four-part report: the outcome, the wave64 problem, how it was fixed in sd-rx580, and the
  llama.cpp continuation.
- Three SVG diagrams: the 32-vs-64 lane comparison, column-per-threadgroup vs tiled matmul,
  and the energy-per-image area chart.
- Six generated images, including the blank white frame as the "before".
- A consolidated *Known failures* section at the back with eleven rows.
- A share card (`assets/og-card.png`, 1200×630) and full SEO metadata.

**Numbers frozen in this version**

| | value |
|---|---|
| speed | 16.26 → 3.88 s/it, 4.19× |
| one image, 20 steps | 325.1 s → 77.6 s |
| electricity per image | 27.1 → 6.5 Wh (derived at 300 W) |
| matrix, f32 / f16 | 0 failures on the plain path |

**Fixes made during review, before freezing**

- Hero stat read "0 → 0 matrix failures", which implied nothing had changed. Replaced with
  27 → 6.5 Wh.
- The matrix table mixed two populations: f32/f16 "before" figures came from the unfiltered
  run, their "after" from the plain-path filter. Marked † and disclosed rather than quietly
  re-filtered.
- "Every Intel-era Mac with a discrete AMD GPU runs 64-wide Metal" was an overclaim. Narrowed
  to GCN (Polaris, Vega); RDNA stated as unverified.
- Support button was a third-party widget that vanished when blocked. Now the branded Ko-fi
  widget with a plain HTML fallback that appears if the widget does not load.

## Unreleased — Chapter 2

llama.cpp on 64-lane hardware. The patch exists
(`llama-cpp/0001-mul-mv-lanes-per-block.patch`); what is missing is the stock-upstream
reproduction, captured before and after.
