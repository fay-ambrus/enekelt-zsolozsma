# Printing and reprinting

The antiphonale is a physical copy that is amended continuously, so it is
reprinted in parts rather than as a whole. Printed states are marked with
tags named `ah-YY-MM` (`ah-26-09`, `ah-26-10`, `ah-26-11`).

## Physical model

A4 sheets are printed two-up duplex, flip on the **short edge**, then **cut in
half** — not folded. Cutting makes the two halves independent A5 leaves, so:

- the smallest replaceable unit is a **leaf**: a recto plus the verso on its back
- the two leaves on one A4 need not be neighbours in the book

Under a short edge flip the front-left half backs onto the reverse-right half,
which is why a sheet reads `[left recto, right recto, right verso, left verso]`.

## reprint.py

Computes which sheets need reprinting between two revisions and emits them
already imposed.

```
python3 reprint.py ah-26-10 ah-26-11          # writes out/...-reprint-ah-26-11.pdf
python3 reprint.py ah-26-10 ah-26-11 --list   # report only
python3 reprint.py ah-26-10 --fold            # whole 4-page gatherings instead
```

Both revisions are read from git with `git show`, so **only committed PDFs are
compared** — a rebuilt but uncommitted `out/` file is invisible.

Pages are paired by their *printed* page number, with a part counter
reconstructed from the numbering restarts, then compared by rendering and
hashing. Any visual difference counts as changed, including a page that merely
shifted and so carries a different header number. The title page is always
reprinted because its subtitle embeds the build month.

## scramble.py

Imposes a PDF into folding order. `--signature 4` (the default) folds every
four pages as their own sheet; `--signature 0` nests the whole document as one
saddle-stitched gathering. Short documents are padded to a multiple of four
with blanks, with the blank placed in the slot the missing page would occupy.

`reprint.py` imposes identically to `scramble.py`, verified by comparison.
