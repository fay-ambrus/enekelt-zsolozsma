gregosheet = gregosheet or {}

local delimiter_s = "¨"
local delimiter_m = "-"
local delimiter_l = "_"
local delimiter_xl = "*"


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

-- Split syllable at first vowel
local function split_syllable(syllable)
  local vowels = "[aáeéiíoóöőuúüűAÁEÉIÍOÓÖŐUÚÜŰ]"
  local pos = syllable:find(vowels) or 1

  local before = syllable:sub(1, utf8.offset(syllable, pos) - 1)
  local vowel_start = utf8.offset(syllable, pos)
  local vowel_end = utf8.offset(syllable, pos + 1)
  local vowel = syllable:sub(vowel_start, vowel_end and vowel_end - 1 or -1)
  local after = vowel_end and syllable:sub(vowel_end) or ""

  return before, vowel, after
end

-- Measure text width in points
local function measure_width(text, fontid)
  if not text or text == "" then return 0 end

  local head, last

  for _, c in utf8.codes(text) do
    local g = node.new("glyph")
    g.font = fontid
    g.char = c
    if not head then
      head = g
    else
      last.next = g
      g.prev = last
    end
    last = g
  end

  return node.hpack(head).width
end

-- Calculate free space between previous and current lyric
local function calculate_free_space(prev_pos, prev_after_width, curr_pos, curr_before_width)
  if not prev_pos then return nil end
  local prev_right = prev_pos + prev_after_width
  local curr_left = curr_pos - curr_before_width
  return curr_left - prev_right
end

function gregosheet.render(melody_str, lyrics_str)
  local melody = parse(melody_str)
  local lyrics = split_lyrics(lyrics_str)
  local lyric_index = 1
  local curr_pos = 0
  local prev_pos = nil
  local prev_after_width = nil

  -- Get font IDs
  local music_fontid = gregosheet.music_fontid
  local lyric_fontid = gregosheet.lyrics_fontid

  local delimiter_s_width = measure_width(delimiter_s, music_fontid)
  local delimiter_m_width = measure_width(delimiter_m, music_fontid)
  local delimiter_l_width = measure_width(delimiter_l, music_fontid)
  local delimiter_xl_width = measure_width(delimiter_xl, music_fontid)
  texio.write_nl("DEBUG: " .. delimiter_s .. " delimiter width=" .. delimiter_s_width .. "pt")
  texio.write_nl("DEBUG: " .. delimiter_m .. " delimiter width=" .. delimiter_m_width .. "pt")
  texio.write_nl("DEBUG: " .. delimiter_l .. " delimiter width=" .. delimiter_l_width .. "pt")
  texio.write_nl("DEBUG: " .. delimiter_xl .. " delimiter width=" .. delimiter_xl_width .. "pt")

  tex.sprint("\\noindent")
  tex.sprint("\\hbox{")

  for i, token in ipairs(melody) do
    if token.type == "note" then
      local lyric = lyrics[lyric_index] or ""
      lyric_index = lyric_index + 1

      local before, vowel, after = split_syllable(lyric)
      local before_width = measure_width(before, lyric_fontid)
      local after_width = measure_width(after, lyric_fontid)

      local free_space = calculate_free_space(prev_pos, prev_after_width, curr_pos, before_width)
      local free_str = free_space and string.format("%.2f", free_space) or "N/A"
      texio.write_nl("DEBUG: lyric=" .. lyric .. " free_space=" .. free_str .. "pt")

      prev_pos = curr_pos
      prev_after_width = after_width
      curr_pos = curr_pos + measure_width(token.value, music_fontid)

      tex.sprint("\\vtop{")
      tex.sprint("\\hbox{\\fontsize{20}{24}\\selectfont\\MusicFont " .. token.value .. "}")
      tex.sprint("\\kern2pt")
      tex.sprint("\\hbox{\\fontsize{10}{12}\\selectfont\\fontspec{Cambria}\\makebox[0pt][r]{" .. before .. "}" .. vowel .. "\\makebox[0pt][l]{" .. after .. "}}")
      tex.sprint("}")


    elseif token.type == "delimiter" then
      curr_pos = curr_pos + measure_width("---", music_fontid)
      tex.sprint("\\vtop{")
      tex.sprint("\\hbox{\\fontsize{20}{24}\\selectfont\\MusicFont ---}")
      tex.sprint("\\kern2pt")
      tex.sprint("\\hbox to 0pt{\\hss}")
      tex.sprint("}")


    elseif token.type == "symbol" then
      curr_pos = curr_pos + measure_width(token.value, music_fontid)
      tex.sprint("\\vtop{")
      tex.sprint("\\hbox{\\fontsize{20}{24}\\selectfont\\MusicFont " .. token.value .. "}")
      tex.sprint("\\kern2pt")
      tex.sprint("\\hbox to 0pt{\\hss}")
      tex.sprint("}")
    end
  end

  tex.sprint("}")
end
