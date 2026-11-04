#!/usr/bin/env bash
# Prepare the container: fetch the gregosheet submodule, then report whether
# everything the books need is actually present.
set -u

echo "== submodules =="
git submodule update --init --recursive 2>&1 | sed 's/^/  /' || \
  echo "  WARNING: could not init submodules"
[ -f gregosheet/gregosheet.sty ] \
  && echo "  gregosheet.sty present" \
  || echo "  WARNING: gregosheet/gregosheet.sty missing"

echo "== toolchain =="
lualatex --version | head -1 | sed 's/^/  /'
lilypond --version | head -1 | sed 's/^/  /'
python3 -c 'import pymupdf, pypdf; print("  " + pymupdf.__doc__.split(":")[0] + ", pypdf " + pypdf.__version__)' \
  2>/dev/null || echo "  WARNING: pymupdf/pypdf unavailable"

echo "== fonts =="
[ -f fonts/GuidoHU.ttf ] \
  && echo "  GuidoHU.ttf present (music font)" \
  || echo "  WARNING: fonts/GuidoHU.ttf missing"
if ls fonts/[Cc][Aa][Mm][Bb][Rr][Ii][Aa]* >/dev/null 2>&1; then
  echo "  Cambria present in fonts/"
else
  echo "  WARNING: Cambria not found. The books will not compile until you run"
  echo "           cp ~/Library/Fonts/Cambria* fonts/"
  echo "           (Caladea is installed and is metric compatible if you would"
  echo "            rather switch styles.tex over to it; see fonts/README.md)"
fi
