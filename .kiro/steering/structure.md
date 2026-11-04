# Structure

```
zsolozsmas-konyvek/          — office books and their lectionarium
vetitesek/                   — projection slides
eneklapok/                   — song sheets for a single occasion
                               (one standalone .tex per publication)

styles.tex                   — shared preamble: fonts, page layout, titles,
                               rubrics, hymn and psalm environments
styles-vetites.tex           — same role for the projection documents
cimlap-viragos.tex           — floral title page fragment (uses kepek/)

ordo-cantus-officii/         — all chant definitions (\defsheet, \deftone)
  1-proprium-de-tempore.tex
  2-psalterium-per-quattuor-hebdomadas-distributum.tex  (+ subdirectory)
  3-proprium-de-sanctis.tex
  4-communia.tex
  5-officium-defunctorum.tex
  6-appendix.tex

gregosheet/                  — git submodule, antiphon typesetting package
                               (github.com/fay-ambrus/gregosheet)
gregosheet-psalm.sty         — psalm package LaTeX interface
gregosheet-psalm/            — its Lua modules (plain directory, not a submodule)

fonts/                       — GuidoHU (tracked) and Cambria (gitignored);
                               see fonts/README.md
kepek/                       — images for title pages
out/                         — compiled PDFs, committed so revisions can be
                               compared for reprinting

reprint.py                   — build a PDF of the sheets changed between two
                               revisions
scramble.py                  — impose a PDF into folding order
.devcontainer/               — LuaLaTeX + LilyPond container
```

Only the three shared fragments stay at the root; everything a document needs
is resolved from the root through `TEXINPUTS`, so documents can sit in
subfolders unchanged. Nothing in a document refers to its own location.

## Conventions

- Directories and files are lowercase ASCII with hyphens, accents stripped
  (`zsolozsmas-konyvek`, `befejezo-imaora`) — never spaces or accents, which
  would have to be escaped in `TEXINPUTS` and on the command line.
- Camp booklets are named `<group>-<kind>-<year>-<season>`.
- Documents never reference each other; they share only the fragments above.
- Output goes to one shared `out/` at the root, not per folder, so `reprint.py`
  and the committed PDFs keep working.
- `out/` is tracked on purpose. `reprint.py` reads both revisions of a PDF
  straight out of git, so committed output is what makes reprinting possible.
