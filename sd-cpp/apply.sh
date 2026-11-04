#!/usr/bin/env bash
# Apply the RX 580 Metal port to a stable-diffusion.cpp checkout.
#
#   git clone https://github.com/thiensubs/wave64-report
#   git clone https://github.com/leejet/stable-diffusion.cpp
#   cd stable-diffusion.cpp
#   git checkout 5356982
#   git submodule update --init --recursive
#   bash ../wave64-report/sd-cpp/apply.sh .
#
# The second argument lets you pick a different base commit, e.g.
#   bash apply.sh ~/src/stable-diffusion.cpp 984eb068
#
# It only runs `git apply` on the two patches that sit next to this script.
# Nothing is downloaded, nothing is installed. Read it before running it.

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-.}"
BASE="${2:-5356982584d5b46a8f5cb0842927aff6443fe174}"

say() { printf '\n\033[1m== %s\033[0m\n' "$1"; }

say "1/4 checking the checkout"
if [ ! -d "$TARGET/ggml/src/ggml-metal" ]; then
  echo "Not a stable-diffusion.cpp checkout: $TARGET" >&2
  echo "Usage: bash apply.sh <path-to-checkout> [base-commit]" >&2
  exit 1
fi
cd "$TARGET"
HEAD_SHA="$(git rev-parse HEAD)"
echo "checkout: $HEAD_SHA"
if [ "$HEAD_SHA" != "$BASE" ]; then
  echo "warning: the patches were generated at $BASE"
  echo "         if this fails, run: git checkout $BASE && git submodule update --init --recursive"
fi

for patch in 0001-ggml-metal-rx580.patch 0002-group-norm-inplace.patch; do
  if [ ! -f "$HERE/$patch" ]; then
    echo "missing $HERE/$patch — clone https://github.com/thiensubs/wave64-report" >&2
    exit 1
  fi
done

say "2/4 applying the group-norm fix"
git apply - < "$HERE/0002-group-norm-inplace.patch"
echo "ok"

say "3/4 applying the Metal port inside ggml/"
( cd ggml && git apply - < "$HERE/0001-ggml-metal-rx580.patch" )
echo "ok"

say "4/4 build it"
cat <<'EOF'
  cmake -B build -DGGML_METAL=ON -DCMAKE_BUILD_TYPE=Release
  cmake --build build --target sd-cli test-backend-ops -j8

Remember: build/bin/kernels/*.metal is copied at build time. Edit a kernel
without rebuilding and you are running the old one.
EOF
