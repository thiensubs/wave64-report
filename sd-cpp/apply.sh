#!/usr/bin/env bash
# Apply the RX 580 Metal port to a stable-diffusion.cpp checkout.
#
# Usage, inside a clean checkout:
#   git clone https://github.com/leejet/stable-diffusion.cpp
#   cd stable-diffusion.cpp
#   git checkout 5356982
#   git submodule update --init --recursive
#   bash apply.sh
#
# The script only runs `git apply`; it downloads the two patches from this page
# and nothing else. Read it before running it — that is the whole point.

set -euo pipefail

BASE="${1:-5356982584d5b46a8f5cb0842927aff6443fe174}"
URL="https://app8601830087.tgcloud.ai/r/rx580-white-images-fix/sd-cpp"

say() { printf '\n\033[1m== %s\033[0m\n' "$1"; }

say "1/4 checking the checkout"
if [ ! -d ggml/src/ggml-metal ]; then
  echo "This is not a stable-diffusion.cpp checkout. Run me from its root." >&2
  exit 1
fi
HEAD_SHA="$(git rev-parse HEAD)"
echo "checkout: $HEAD_SHA"
if [ "$HEAD_SHA" != "$BASE" ]; then
  echo "warning: the patches were generated at $BASE — if this fails, run:"
  echo "  git checkout $BASE && git submodule update --init --recursive"
fi

say "2/4 applying the group-norm fix"
curl -fsSL "$URL/0002-group-norm-inplace.patch" | git apply -
echo "ok"

say "3/4 applying the Metal port inside ggml/"
( cd ggml && curl -fsSL "$URL/0001-ggml-metal-rx580.patch" | git apply - )
echo "ok"

say "4/4 build it"
cat <<'EOF'
  cmake -B build -DGGML_METAL=ON -DCMAKE_BUILD_TYPE=Release
  cmake --build build --target sd-cli test-backend-ops -j8

Remember: build/bin/kernels/*.metal is copied at build time. Edit a kernel
without rebuilding and you are running the old one.
EOF
