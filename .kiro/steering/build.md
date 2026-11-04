# Building

LuaLaTeX only — the packages are Lua based and the documents use `fontspec`.
`--shell-escape` is required because six documents call LilyPond through
`lyluatex` (`nagyhet-2026`, `nagyhet-vetites`, `temetes`, `temetesi-mise`,
`urnapja`, `urnapja-vetites`).

```
TEXINPUTS="$R:$R/gregosheet:$R/gregosheet-psalm:" \
LUAINPUTS="$R:$R/gregosheet:$R/gregosheet-psalm:" \
OSFONTDIR="$R/fonts" \
lualatex --shell-escape -interaction=nonstopmode -output-directory=out \
  zsolozsmas-konyvek/antiphonale-hungaricum.tex
```

where `$R` is the repository root. Because documents live in subfolders, every
search path must point at the root, not at the document's directory: VS Code
uses `%WORKSPACE_FOLDER%` rather than `%DIR%` throughout
`.vscode/settings.json`, and writes to one shared `%WORKSPACE_FOLDER%/out`.
Building on save is enabled.

## Font resolution — the one real trap

`TEXINPUTS` does **not** find fonts. `fontspec`/`luaotfload` resolves font
files through `OSFONTDIR` (or the current working directory), so
`OSFONTDIR` must point at `fonts/` or `GuidoHU.ttf` silently fails to load.
Images are fine: `\graphicspath{{kepek/}}` does resolve through `TEXINPUTS`.

Cambria is required by `styles.tex` and is not redistributable, so it is
gitignored and must be copied in once:

    cp ~/Library/Fonts/Cambria* fonts/

fontconfig aliasing does not help — luaotfload ignores fontconfig aliases, so
a free metric-compatible substitute cannot stand in under the name "Cambria"
without editing `styles.tex`.

## Devcontainer

`.devcontainer/` provides TeX Live 2026, LilyPond, and the Python stack. TeX
Live matches the host version, and chant documents have been verified
pixel-identical to a macOS build. `OSFONTDIR`, `TEXINPUTS` and `LUAINPUTS` are
set in `devcontainer.json`; `postCreate.sh` initialises the gregosheet
submodule and reports anything missing.

LilyPond does **not** match: the container has Debian's 2.24.4 while the host
has 2.26.0, so the six `lyluatex` documents can paginate differently between
the two (`nagyhet-2026` gives 73 pages in the container and 66 on the host).
Build those on one machine consistently, or install matching LilyPond versions.
`nagyhet-2026` also exits 1 from a lyluatex error in both environments while
still producing a PDF; this is long-standing and unrelated to layout.

## Submodule

`gregosheet` is a submodule. After cloning run
`git submodule update --init --recursive`, or the build fails on
`\usepackage{gregosheet}`.
