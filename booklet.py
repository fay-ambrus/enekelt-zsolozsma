#!/usr/bin/env python3
"""Reorder a PDF for saddle-stitched booklet printing.

Pages are padded to a multiple of four with blanks and reordered into folding
order, one page per sheet side. Print the result two-up, duplex, flip on the
short edge, then fold in the middle.

    python3 booklet.py out/bori-bence-eskuvo-nep.pdf
    python3 booklet.py --signature 16 out/antiphonale-hungaricum.pdf

Requires pypdf.
"""

from __future__ import annotations

import argparse
import os
import sys

from pypdf import PageObject, PdfReader, PdfWriter


def booklet_order(count: int, signature: int) -> list[int | None]:
    """Return page indices in folding order; ``None`` marks a blank page.

    ``count`` is the number of real pages, ``signature`` the number of pages per
    folded gathering (a multiple of four, or 0 for a single gathering).
    """
    padded = (count + 3) // 4 * 4
    if signature <= 0:
        signature = padded
    elif signature % 4:
        raise ValueError("signature size must be a multiple of 4")

    order: list[int | None] = []
    for start in range(0, padded, signature):
        size = min(signature, padded - start)
        for sheet in range(size // 4):
            first, last = start + 2 * sheet, start + size - 1 - 2 * sheet
            # front of the sheet, then its back
            order += [last, first, first + 1, last - 1]
    return [p if p < count else None for p in order]


def blank_size(reader: PdfReader) -> tuple[float, float]:
    """Largest page width and height in the document, in points."""
    sizes = []
    for page in reader.pages:
        box = page.mediabox
        w, h = float(box.width), float(box.height)
        if (page.get("/Rotate") or 0) % 180:
            w, h = h, w
        sizes.append((w, h))
    return max(w for w, _ in sizes), max(h for _, h in sizes)


def process(path: str, args: argparse.Namespace) -> None:
    reader = PdfReader(path)
    order = booklet_order(len(reader.pages), args.signature)
    width, height = blank_size(reader)

    writer = PdfWriter()
    for index in order:
        if index is None:
            writer.add_page(PageObject.create_blank_page(width=width, height=height))
        else:
            writer.add_page(reader.pages[index])

    base, ext = os.path.splitext(path)
    out = args.output or base + "-booklet" + ext
    with open(out, "wb") as handle:
        writer.write(handle)

    blanks = sum(1 for p in order if p is None)
    print(f"{path}: {len(reader.pages)} pages"
          f"{f' + {blanks} blank' if blanks else ''}"
          f" -> {out} ({len(writer.pages)} pages)")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Reorder a PDF for saddle-stitched booklet printing.")
    parser.add_argument("files", nargs="+", metavar="PDF")
    parser.add_argument("-o", "--output",
                        help="output file (only with a single input)")
    parser.add_argument("-s", "--signature", type=int, default=0, metavar="N",
                        help="pages per folded gathering, multiple of 4 "
                             "(default: fold the whole document as one)")
    args = parser.parse_args(argv)

    if args.output and len(args.files) > 1:
        parser.error("--output cannot be combined with several input files")

    for path in args.files:
        try:
            process(path, args)
        except (OSError, ValueError) as error:
            print(f"{path}: {error}", file=sys.stderr)
            return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
