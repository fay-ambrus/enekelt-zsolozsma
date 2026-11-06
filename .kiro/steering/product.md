# Énekelt zsolozsma — product

Hungarian-language Gregorian chant publications, typeset with LuaLaTeX and
printed on paper for liturgical use. The repository is both the source of the
books and the tooling that produces and reprints them.

## Purpose

Chant is typeset from plain-text melody and lyric strings rather than engraved
by hand, so a chant can be defined once and reused across any number of
publications. Two in-house LaTeX packages do that work: `gregosheet` for
antiphons and `gregosheet-psalm` for psalm tones.

## Publications

All documents are standalone `.tex` files compiled individually. There is no
single master document. They are grouped into three folders by kind.

| Folder | Documents |
|---|---|
| `zsolozsmas-konyvek/` — office books | `antiphonale-hungaricum`, `befejezo-imaora`, `napkozi-imaora`, `cserkesz-zsolozsma-2026-nyar`, `cserkesz-lectionarium-2026-nyar`, `kosza-zsolozsma-2026-tavasz`, `kosza-zsolozsma-2026-nyar`, `kosza-zsolozsma-2026-osz` |
| `vetitesek/` — projections | `nagyhet-vetites`, `urnapja-vetites` — 105 mm wide slides, use `styles-vetites.tex` |
| `eneklapok/` — song sheets for an occasion | `bori-bence-eskuvo`, `bori-bence-eskuvo-nep`, `nagyhet-2026`, `temetes`, `temetesi-mise`, `urnapja` |

`antiphonale-hungaricum` is the principal work: an A5 antiphonale, currently
~228 pages, continuously amended and reprinted in parts. Its page numbering
restarts in each of its six parts, and `\padtotwo` pads every part to a
multiple of two pages so the next part begins on a recto. That matches the
unit of paper: the copy is cut in half rather than folded, so a leaf of two
pages is what gets replaced. It was `\padtofour` while the copy was folded
into four-page gatherings.

## Shared sources

Chant definitions live in `ordo-cantus-officii/`, organised after the Roman
*Ordo cantus officii*: temporale, psalterium in four weeks, sanctorale,
communia, officium defunctorum, appendix. Documents pull in the parts they
need with `\input`, so the same antiphon serves a camp booklet and the
antiphonale alike.
