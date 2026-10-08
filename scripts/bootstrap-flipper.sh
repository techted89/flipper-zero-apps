#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [ ! -d "$ROOT_DIR/firmware/.git" ]; then
  echo "Initializing firmware submodule..."
  git submodule update --init --recursive
fi

if [ ! -f "$ROOT_DIR/firmware/fbt" ]; then
  echo "The official Flipper Zero firmware repo was not found in ./firmware."
  echo "Run: git submodule update --init --recursive"
  exit 1
fi

echo "Flipper Zero firmware dependency is present."
echo "Next steps:"
echo "  cd $ROOT_DIR/firmware"
echo "  ./fbt"
echo "  ./fbt fap_example_hello"
