# wave64-report

**Read it:** https://app8601830087.tgcloud.ai/r/rx580-white-images-fix/ — the canonical copy,
inside Telegram.

**Chapter 1 of a series.** How Stable Diffusion 2.1 was made to run correctly on an AMD
RX 580 through Metal, and how it got **4.19x faster** in the process.

**Chapter 2 (in progress).** llama.cpp on 64-lane hardware. Upstream documents the defect in a
comment and refuses those formats on wide devices; the patch is written and the whitelist-removed
run is what remains. Materials in `llama-cpp/`.

Open `index.html` in any browser. No build step, no dependencies.

## Contents

| Part | What it covers |
|---|---|
| 1 - The win | The outcome in numbers, the energy chart, the image gallery |
| 2 - The problem | Why a GPU wave is a rowing boat; 32 vs 64 lanes; who is affected |
| 3 - How it happened | Four bugs in the order they were found, the matrix, the tiling diagrams |
| 4 - Chapter 2 | What upstream says, the three-hunk patch, the policy that shapes it |
| Appendix | Paths, reproduce commands, numbers, traps, and every known failure |

## Support

The **"Keep the AI cooking"** button is the official Ko-fi widget
(`Widget_2.js`, coral `#f59273`, ID `R0C02A133C`), so it carries the Ko-fi logo.

A plain HTML button with the same label and colour is the default underneath. If the widget
loads, JavaScript hides the duplicate; if the script is blocked, offline, or the page is
rendered without scripts, the plain button is what remains. The page never shows a gap.

A Ko-fi floating overlay (`overlay-widget.js`) sits in the corner. Purely decorative: if it
fails, the main button is unaffected.

For a GitHub repository, `.github/FUNDING.yml` declares the same account, so GitHub shows a
Sponsor button on the repo.

## Slug

`validateSlug` in `tgsearch/telegram/miniapp/scripts/slug.mjs` allows <=24 characters and <=4
hyphen-words. All four candidates below were run through that function:

| slug | chars | words | why |
|---|---|---|---|
| **`rx580-white-images-fix`** | 22 | 4 | **Recommended.** Symptom and payoff. "white image" is what people search; `-fix` earns the click. |
| `rx580-blank-images` | 18 | 3 | Sharper word, six characters of headroom, no payoff signal. |
| `rx580-painted-white` | 19 | 3 | Most curiosity, no search volume. |
| `stable-diffusion-rx580` | 22 | 3 | Best keyword match, zero hook. |

The slug is a permanent public URL, so pick once. For Chapter 2 keep the shape consistent:
`llama-cpp-wave64` (16).

## Metadata

Description, Open Graph, Twitter card, JSON-LD `TechArticle`, and `assets/og-card.png` as the
share image. When the page gets a URL:

1. Add absolute `canonical`, `og:url` and `og:image`. Telegram and Discord resolve relative
   paths; Facebook does not. Marked with a comment in `<head>`.
2. Check the preview with the platform's own debugger, not by reading the tags.

## Versioning

`VERSION` holds the current version; `CHANGELOG.md` records each frozen snapshot.

Current: **v1.1**, 2026-11-04. v1.1 is a correction, not a feature: Part 4 had implied the
llama.cpp defect was unknown, when upstream documents it in a comment and routes around it. The
AI-written PR draft was also deleted, because llama.cpp prohibits exactly that artifact.

Once a chapter is published under its slug, its content stops changing: corrections ship as a
new version with a changelog entry, never as a silent edit to a URL someone may have cited.

## Publish to GitHub

Not done yet. These are the commands for the person who owns the account — nothing here
pushes on its own.

```bash
cd wave64-report
git init -b main
git add .
git commit -m "wave64 chapter 1: SD 2.1 on an RX 580, v1.2"
gh repo create wave64-report --public --source=. --remote=origin --push
```

Then, once:

1. **Settings → Pages → Source: GitHub Actions.** `.github/workflows/pages.yml` publishes this
   folder on every push to `main`; there is nothing to build.
2. **Settings → General → Social preview** → upload `assets/og-card.png`.
3. Fill the repository description with the one-line summary. It is what a search result shows.

`FUNDING.yml` already points at Ko-fi, so the Sponsor button appears with no further setup.

**One thing to preserve:** the GitHub Pages copy and the tgcloud copy are the same document.
`index.html` names the tgcloud URL as `<link rel="canonical">`, so search engines credit one
page instead of two. Keep that line when editing, or the two mirrors start competing.

## Files

```
index.html                             the report (self-contained)
VERSION                                current version (1.2)
CHANGELOG.md                           what each frozen snapshot contains
LICENSE                                MIT
.gitignore                             .DS_Store, scratch dirs
.github/workflows/pages.yml            publishes this folder as a static site
.github/FUNDING.yml                    Ko-fi sponsor button
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
- **Measured on hardware, same source shape:** the q4/q5 lane defect (43 failures before,
  0 after).
- **Observed on a stock build:** llama.cpp refuses q4_0 on this card - every case reports
  `not supported [MTL0]`. That is the workaround, not the bug.
- **Not done:** the whitelist-removed run on a stock checkout. That is Chapter 2's remaining
  job, and the report says so in three places.
- **Not attempted:** MI300, RDNA, or any second AMD Metal device. One card was available.

## Provenance

RX 580 (Polaris, gfx803), macOS, patched `ggml` Metal backend, Stable Diffusion 2.1
`v2-1_512-ema-pruned`, 512x512, 20 steps, euler-a, cfg 7.0.
Engineering board: `sd-rx580/docs/wave64-board.md`.
