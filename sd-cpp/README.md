# The RX 580 Metal port — patches for stable-diffusion.cpp

The code behind the report *Stable Diffusion on an RX 580: 4.19× faster, no blank
images*. Two patches, applied on top of a clean upstream checkout.

## Provenance

| Thing | Value |
|---|---|
| upstream | `leejet/stable-diffusion.cpp` @ `5356982584d5b46a8f5cb0842927aff6443fe174` |
| `ggml` submodule | `d49c49e1dd361ba3c0a77c90b5b1404b83969aa8` |
| generated | 2026-11-04, from the fork's working tree — the work was uncommitted |
| apply point | both patches pass `git apply --check` at exactly those two commits (verified 2026-11-04) |

## Files

| File | Contents |
|---|---|
| `0001-ggml-metal-rx580.patch` | the `ggml` submodule diff — 24 files: Metal device/ops/impl, simdgroup width 64, `fa_vec_*` guards, the tiled SIMT GEMM in `mul_mv.metal`, padded threadgroup memory, `norm.metal`, `ssm.metal` |
| `0002-group-norm-inplace.patch` | `src/core/ggml_extend.cpp` — `group_norm` used `mul_inplace`/`add_inplace`; switched to the out-of-place ops |

Both files are plain `git diff` output. Nothing else in the tree was changed.

## Apply

### One command (the helper)

```bash
git clone https://github.com/leejet/stable-diffusion.cpp
cd stable-diffusion.cpp
git checkout 5356982
git submodule update --init --recursive
curl -O https://app8601830087.tgcloud.ai/r/rx580-white-images-fix/sd-cpp/apply.sh
bash apply.sh
```

`apply.sh` only runs `git apply`, checks the checkout SHA, and prints the build
command. Read it before running it.

### By hand

```bash
git clone https://github.com/leejet/stable-diffusion.cpp
cd stable-diffusion.cpp
git checkout 5356982
git submodule update --init --recursive

git apply /path/to/0002-group-norm-inplace.patch

cd ggml
git apply /path/to/0001-ggml-metal-rx580.patch
cd ..
```

`0001` applies inside `ggml/` because its paths are relative to that submodule.

## Build (Mac with Metal)

```bash
cmake -B build -DGGML_METAL=ON -DCMAKE_BUILD_TYPE=Release
cmake --build build --target sd-cli test-backend-ops -j8
```

**Stale kernels:** the build copies `kernels/*.metal` into `build/bin/kernels/`.
Editing a kernel without rebuilding runs the old one — a silent no-op on this
port. Rebuild after touching any `.metal` file.

## What the port changes

Three correctness fixes and one performance idea — see `ALGORITHM.md`. At a
simdgroup width of 32 every new expression reduces to the old one, which is what
makes the patch reviewable on Apple Silicon.

## Status

Uncommitted work in the author's fork; the numbers in the report were measured
with it. No benchmark claim is made in this file.
