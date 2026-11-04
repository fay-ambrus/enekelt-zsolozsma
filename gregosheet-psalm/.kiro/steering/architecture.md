# gregosheet-psalm

A LuaLaTeX package for setting psalm verses to a recitation tone. It is the
companion to `gregosheet`: that package engraves antiphons as notes, this one
marks up pointed psalm text so cantors know where the tone inflects.

Unlike `gregosheet`, this is a plain directory in the `enekelt-zsolozsma`
repository, not a submodule.

## Interface

```latex
\begin{psalmsheet}[tone={...}, number={...}, title={...}, motto={...},
                   numeral={...}, initium, continuous]
  \psalmtext{Psalm text, verses separated as the syllabifier expects}
\end{psalmsheet}
```

| Option | Effect |
|---|---|
| `tone` | the recitation tone to point the text against |
| `number`, `numeral` | psalm number and numeral as printed |
| `title`, `motto` | heading and motto lines |
| `initium` | include the intonation formula |
| `continuous` | run on from the previous psalm rather than starting afresh |

`\psalmtext` stores the body; the environment's end hook passes everything to
Lua in one call. Inside the environment `_`, `^` and `$` are catcode 12, as in
`gregosheet`, because the markup uses them literally.

## File structure

```
gregosheet-psalm.sty                   — LaTeX interface, option parsing (l3keys)
gregosheet-psalm/
  gregosheet-psalm.syllabify.lua       — Hungarian syllabification
  gregosheet-psalm.marking.lua         — mark_flexa, mark_mediatio, mark_terminatio
  gregosheet-psalm.render.lua          — emit TeX output
  gregosheet-psalm.main.lua            — orchestrator called by the environment
```

Modules are required with an explicit directory prefix
(`require("gregosheet-psalm/gregosheet-psalm.marking")`), so `LUAINPUTS` must
contain the repository root, not just this directory.

## Pipeline

Text is syllabified, then the cadence points are marked in order — flexa,
mediatio, terminatio — and the result is rendered. Marking is where the
liturgical logic sits: it decides which syllables carry the inflection for the
given tone.

## Maintaining this note

Keep it true. When the interface, options, module layout or pipeline change,
update this file as part of the same work, unasked. Record general structure
and purpose, not task history.
