#!/bin/sh
# Run inside Omarchy on the J716c: curl -fsSL https://raw.githubusercontent.com/vadim-su/omarchy-j716c/main/go.sh | sh
set -e
echo "== cores: $(nproc)  gpu nodes: $(ls /dev/dri 2>/dev/null | tr '\n' ' ')"
dir="$HOME/omarchy-j716c"
if [ -d "$dir/.git" ]; then git -C "$dir" pull -q; else git clone -q https://github.com/vadim-su/omarchy-j716c "$dir"; fi
command -v omp >/dev/null 2>&1 || curl -fsSL https://omp.sh/install | sh
export PATH="$HOME/.local/bin:$PATH"
echo
echo "Ready. Start the assistant:"
echo "  cd $dir && omp"
echo "First time: log in to your model provider inside omp (/login), then say:"
echo "  'Прочитай HANDOFF.md и продолжай'"
