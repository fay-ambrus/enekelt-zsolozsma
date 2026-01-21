gregosheet = gregosheet or {}

-- Parse string into tokens: notes, delimiters (-), and symbols
local function parse(str)
  local tokens = {}
  local notes = "[ðñ0123456789öüó%^qwertzuiopõúÝÞQWERTZUIOPÕÚÔ×asdfghjkléáûØÙASDFGHJKLÉÁÛ`íyxcvbnmzZ÷øÍYXCVBNŸ¡¢£¥¦©ª«¬àâãäåæçèêëìîï%]]"
  local delimiters = "[%-_¨*]"
  local symbols = "[¼ÿ®−§'\"+!%%/=()ÖÜÓ%s,M?>#&@{}<¿À]"
  local note_group = ""
  local last_type = nil

  for char in str:gmatch(".") do
    if char:match(notes) then
      note_group = note_group .. char
      last_type = "note"
    elseif char:match(delimiters) then
      if note_group ~= "" then
        table.insert(tokens, {type = "note", value = note_group})
        note_group = ""
      end
      if last_type ~= "delimiter" then
        table.insert(tokens, {type = "delimiter", value = "-"})
      end
      last_type = "delimiter"
    elseif char:match(symbols) then
      if note_group ~= "" then
        table.insert(tokens, {type = "note", value = note_group})
        note_group = ""
      end
      table.insert(tokens, {type = "symbol", value = char})
      last_type = "symbol"
    end
  end

  if note_group ~= "" then
    table.insert(tokens, {type = "note", value = note_group})
  end

  return tokens
end

-- Split lyrics by spaces and hyphens
local function split_lyrics(str)
  local syllables = {}
  for syllable in str:gmatch("[^%s%-]+") do
    table.insert(syllables, syllable)
  end
  return syllables
end

function gregosheet.render(melody_str, lyrics_str)
  local melody = parse(melody_str)
  local lyrics = split_lyrics(lyrics_str)
  local lyric_index = 1

  tex.sprint("\\noindent")
  tex.sprint("\\hbox{")

  for i, token in ipairs(melody) do
    if token.type == "note" then
      local lyric = lyrics[lyric_index] or ""
      lyric_index = lyric_index + 1

      tex.sprint("\\vtop{")
      tex.sprint("\\hbox{\\fontsize{20}{24}\\selectfont\\MusicFont " .. token.value .. "}")
      tex.sprint("\\kern2pt")
      tex.sprint("\\hbox to 0pt{\\hss\\fontsize{10}{12}\\selectfont\\fontspec{Cambria}" .. lyric .. "\\hss}")
      tex.sprint("}")
    elseif token.type == "delimiter" then
      tex.sprint("\\vtop{")
      tex.sprint("\\hbox{\\fontsize{20}{24}\\selectfont\\MusicFont ---}")
      tex.sprint("\\kern2pt")
      tex.sprint("\\hbox to 0pt{\\hss}")
      tex.sprint("}")
    elseif token.type == "symbol" then
      tex.sprint("\\vtop{")
      tex.sprint("\\hbox{\\fontsize{20}{24}\\selectfont\\MusicFont " .. token.value .. "}")
      tex.sprint("\\kern2pt")
      tex.sprint("\\hbox to 0pt{\\hss}")
      tex.sprint("}")
    end
  end

  tex.sprint("}")
end
