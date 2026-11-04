#!/usr/bin/env python3
"""Build a PDF of the sheets that need reprinting between two revisions.

Both revisions of the typeset PDF are read straight out of git, so nothing is
rebuilt. Pages are paired by their *printed* page number -- numbering restarts
in every part of the book, so a part counter is reconstructed from the resets --
and compared by rendering them and hashing the result. A page counts as changed
whenever it looks different, is brand new, or carries the title page.

Changed pages are then grown to whole leaves -- a recto plus the verso printed
on its back -- which is the smallest piece of paper that can be swapped into a
copy whose A4 sheets were cut in half rather than folded. Two leaves share one
A4 and need not be neighbours in the book, so a single changed page costs two
pages of paper instead of four. Print two-up, duplex, flip on the short edge,
then cut down the middle.

Pass ``--fold`` for a copy that is folded instead of cut; changed pages then
grow to whole four page gatherings, imposed exactly as ``scramble.py`` would.

    python3 reprint.py ah-26-09 ah-26-10
    python3 reprint.py ah-26-09 HEAD --list
    python3 reprint.py ah-26-09 ah-26-10 -o out/potlas-26-10.pdf

Requires pymupdf and pypdf.
"""

from __future__ import annotations

import argparse
import hashlib
import os
import re
import subprocess
import sys
import tempfile
from dataclasses import dataclass

try:  # PyMuPDF renamed its module; the "fitz" alias is deprecated
    import pymupdf as fitz
except ImportError:  # PyMuPDF older than 1.24
    import fitz
from pypdf import PageObject, PdfReader, PdfWriter

from scramble import blank_size, folding_order

DOCUMENT = "out/antiphonale-hungaricum.pdf"
HEADER_HEIGHT = 40.0
ROMAN = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X"]


@dataclass
class Page:
    """One physical page of a revision."""

    index: int  # zero based physical page index
    part: int  # zero based part number, counted from numbering restarts
    label: str  # printed page number, or "title" / "blank N"
    digest: str  # hash of the rendered page

    @property
    def key(self) -> tuple[int, str]:
        return self.part, self.label

    def __str__(self) -> str:
        return f"{ROMAN[self.part]}/{self.label}"


def git_show(repo: str, ref: str, path: str) -> bytes:
    """Return the contents of ``path`` as of ``ref``."""
    result = subprocess.run(
        ["git", "-C", repo, "show", f"{ref}:{path}"],
        capture_output=True,
    )
    if result.returncode:
        message = result.stderr.decode(errors="replace").strip()
        raise ValueError(f"cannot read {path} at {ref}: {message}")
    return result.stdout


def printed_number(page: fitz.Page) -> int | None:
    """The page number shown in the running head, if the page has one.

    The number sits in the outer corner, so on a recto the rightmost figure in
    the header is taken and on a verso the leftmost. Title and padding pages use
    an empty page style and yield ``None``.
    """
    box = page.rect
    header = fitz.Rect(box.x0, box.y0, box.x1, box.y0 + HEADER_HEIGHT)
    found = [w for w in page.get_text("words", clip=header)
             if re.fullmatch(r"\d+", w[4])]
    if not found:
        return None
    recto = page.number % 2 == 0  # zero based, so page 1 is index 0
    outer = max(found, key=lambda w: w[2]) if recto else min(found, key=lambda w: w[0])
    return int(outer[4])


def index_revision(data: bytes, dpi: int) -> list[Page]:
    """Describe every page of a revision, in physical order."""
    pages: list[Page] = []
    with fitz.open(stream=data, filetype="pdf") as document:
        part, previous, blanks = 0, None, 0
        for page in document:
            number = printed_number(page)
            if number is not None and previous is not None and number <= previous:
                part, blanks = part + 1, 0  # numbering restarted: a new part
            if page.number == 0:
                label = "title"
            elif number is None:
                blanks += 1
                label = f"blank {blanks}"
            else:
                label, previous = str(number), number
            pixmap = page.get_pixmap(dpi=dpi, colorspace=fitz.csGRAY)
            digest = hashlib.sha256(
                f"{pixmap.width}x{pixmap.height}".encode() + pixmap.samples
            ).hexdigest()
            pages.append(Page(page.number, part, label, digest))
    return pages


def changed_pages(old: list[Page], new: list[Page],
                  keep_title: bool) -> tuple[list[Page], list[Page]]:
    """Pages of ``new`` that need reprinting, and pages ``old`` has lost."""
    before = {page.key: page for page in old}
    changed = [page for page in new
               if (keep_title and page.label == "title")
               or page.key not in before
               or before[page.key].digest != page.digest]
    current = {page.key for page in new}
    return changed, [page for page in old if page.key not in current]


def sheets_of(pages: list[Page], total: int, unit: int) -> list[list[int | None]]:
    """Whole gatherings covering ``pages``, as physical page indices.

    A gathering always has ``unit`` slots; ``None`` marks a slot past the end of
    the document, which is printed as a blank so the sheet still folds.
    """
    wanted = sorted({page.index // unit for page in pages})
    return [[i if i < total else None
             for i in range(first * unit, (first + 1) * unit)]
            for first in wanted]


def impose(sheet: list[int | None], unit: int) -> list[int | None]:
    """Reorder one gathering for folding, as ``scramble.py`` does."""
    return [sheet[i] for i in folding_order(unit, unit)]


def leaf_slots(leaf: int | None, total: int) -> tuple[int | None, int | None]:
    """The recto and verso of a leaf, ``None`` where the document has ended."""
    if leaf is None:
        return None, None
    recto, verso = 2 * leaf, 2 * leaf + 1
    return (recto if recto < total else None,
            verso if verso < total else None)


def cut_sheets(leaves: list[int], total: int,
               folding: bool) -> list[list[int | None]]:
    """A4 sheets carrying two leaves each, for a copy that is cut in half.

    Under a short edge duplex flip the left half of the front backs onto the
    right half of the reverse, so an A4 reads left recto, right recto, right
    verso, left verso. Cut it down the middle and both leaves come out the right
    way round, whether or not they sit together in the book.
    """
    sheets = []
    for first in range(0, len(leaves), 2):
        pair = leaves[first:first + 2]
        left = leaf_slots(pair[0], total)
        right = leaf_slots(pair[1] if len(pair) > 1 else None, total)
        sheets.append([left[0], right[0], right[1], left[1]] if folding
                      else [left[0], left[1], right[0], right[1]])
    return sheets


def ranges(labels: list[str]) -> str:
    """Collapse consecutive printed numbers into ``first-last`` ranges."""
    out: list[str] = []
    for label in labels:
        if not label.isdigit() or not out:
            out.append(label)
            continue
        first, _, last = out[-1].partition("-")
        if (last or first).isdigit() and int(last or first) + 1 == int(label):
            out[-1] = f"{first}-{label}"
        else:
            out.append(label)
    return ", ".join(out)


def summarise(changed: list[Page], size: int, noun: str) -> None:
    """Report the changed pages per part, and the units of paper they need."""
    for part in sorted({page.part for page in changed}):
        mine = [page for page in changed if page.part == part]
        units = len({page.index // size for page in mine})
        print(f"  part {ROMAN[part]:<4} {len(mine):3} changed page(s), "
              f"{units:3} {noun}")
        print(f"    changed: {ranges([page.label for page in mine])}")


def process(repo: str, old_ref: str, new_ref: str,
            args: argparse.Namespace) -> int:
    old = index_revision(git_show(repo, old_ref, args.document), args.dpi)
    new_data = git_show(repo, new_ref, args.document)
    new = index_revision(new_data, args.dpi)

    changed, removed = changed_pages(old, new, not args.no_title)

    print(f"{args.document}: {old_ref} ({len(old)} pages) "
          f"-> {new_ref} ({len(new)} pages)")
    if not changed:
        print("  nothing changed, no sheets to print")
        return 0

    if args.fold:
        size, noun = args.unit, "gathering(s)"
        sheets = sheets_of(changed, len(new), args.unit)
        if not args.no_impose:
            sheets = [impose(sheet, args.unit) for sheet in sheets]
        units = len(sheets)
    else:
        size, noun = 2, "leaf/leaves"
        leaves = sorted({page.index // 2 for page in changed})
        sheets = cut_sheets(leaves, len(new), not args.no_impose)
        units = len(leaves)

    summarise(changed, size, noun)
    pages = sum(len(sheet) for sheet in sheets)
    print(f"  {len(changed)} changed page(s) -> {units} {noun} "
          f"-> {len(sheets)} sheet(s) = {pages} page(s) to print")
    if removed:
        print(f"  gone from {new_ref}: "
              f"{', '.join(str(page) for page in removed)}")
    if args.list:
        return 0

    with tempfile.TemporaryDirectory() as workspace:
        source = os.path.join(workspace, "new.pdf")
        with open(source, "wb") as handle:
            handle.write(new_data)
        reader = PdfReader(source)
        writer = PdfWriter()
        width, height = blank_size(reader)
        for sheet in sheets:
            for i in sheet:
                if i is None:
                    writer.add_page(
                        PageObject.create_blank_page(width=width, height=height))
                else:
                    writer.add_page(reader.pages[i])
        base, ext = os.path.splitext(os.path.basename(args.document))
        stamp = re.sub(r"[^\w.-]", "-", new_ref)
        out = args.output or os.path.join(
            os.path.dirname(args.document), f"{base}-reprint-{stamp}{ext}")
        os.makedirs(os.path.dirname(out) or ".", exist_ok=True)
        with open(out, "wb") as handle:
            writer.write(handle)
    kind = ("in document order" if args.no_impose
            else "imposed for folding" if args.fold
            else "imposed for cutting in half")
    print(f"  wrote {out} ({len(writer.pages)} pages, {kind})")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Build a PDF of the sheets changed between two revisions.")
    parser.add_argument("old", metavar="OLD", help="tag or commit already printed")
    parser.add_argument("new", metavar="NEW", nargs="?", default="HEAD",
                        help="tag or commit to print (default: HEAD)")
    parser.add_argument("-d", "--document", default=DOCUMENT, metavar="PDF",
                        help=f"PDF path inside the repository (default: {DOCUMENT})")
    parser.add_argument("-o", "--output", metavar="PDF", help="output file")
    parser.add_argument("-C", "--repo", default=".", metavar="DIR",
                        help="repository to read (default: current directory)")
    parser.add_argument("-f", "--fold", action="store_true",
                        help="the copy is folded, not cut: grow changes to "
                             "whole gatherings and impose for folding")
    parser.add_argument("-u", "--unit", type=int, default=4, metavar="N",
                        help="pages per gathering with --fold (default: 4)")
    parser.add_argument("--dpi", type=int, default=150,
                        help="resolution pages are compared at (default: 150)")
    parser.add_argument("-l", "--list", action="store_true",
                        help="only report, do not write a PDF")
    parser.add_argument("--no-impose", action="store_true",
                        help="keep document order instead of printing order")
    parser.add_argument("--no-title", action="store_true",
                        help="reprint the title page only if it changed")
    args = parser.parse_args(argv)

    if args.unit < 1:
        parser.error("--unit must be positive")
    if args.fold and args.unit % 4 and not args.no_impose:
        parser.error("--unit must be a multiple of 4 to impose for folding; "
                     "pass --no-impose to keep document order")
    try:
        return process(args.repo, args.old, args.new, args)
    except (OSError, ValueError) as error:
        print(f"{error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
