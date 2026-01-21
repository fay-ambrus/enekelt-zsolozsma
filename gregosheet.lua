gregosheet = gregosheet or {}

-- split string by spaces
local function split(str)
  local t = {}
  for s in string.gmatch(str, "%S+") do
    table.insert(t, s)
  end
  return t
end

function gregosheet.render(melody_str, lyrics_str)
  local melody = split(melody_str)
  local lyrics = split(lyrics_str)

  tex.sprint("\\noindent")
  tex.sprint("\\hbox{")

  for i, note in ipairs(melody) do
    local lyric = lyrics[i] or ""

    tex.sprint("\\vbox{")
    tex.sprint("\\hbox{\\MusicFont " .. note .. "}")
    tex.sprint("\\kern2pt")
    tex.sprint("\\hbox{\\footnotesize " .. lyric .. "}")
    tex.sprint("}")
    tex.sprint("\\kern6pt")
  end

  tex.sprint("}")
end
