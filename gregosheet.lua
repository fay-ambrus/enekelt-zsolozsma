gregosheet = gregosheet or {}

local delimiter_s = "¨"
local delimiter_m = "-"
local delimiter_l = "_"

local std_delimiter_sequence = "---"

local tolerable_syllabel_gap_sp = 73000

-- Code table
local notes = "[ðñ0123456789öüó%^qwertzuiopõúÝÞQWERTZUIOPÕÚÔ×asdfghjkléáûØÙASDFGHJKLÉÁÛ`íyxcvbnmzZ÷øÍYXCVBNŸ¡¢£¥¦©ª«¬àâãäåæçèêëìîï%]¨]"
local recited_notes = "[%[Ÿ¡¢£¥¦©ª«¬]"
local delimiters = "[%-_*]"
local symbols = "[¼ÿ®−§'\"+!%%/=()ÖÜÓ%s,M?>#&@{}<¿À:.]"

-- Measure text width in scaled points
local function measure_width_sp(text, fontid)
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

-- Parse string into tokens: notes, delimiters, and symbols
local function parse_melody(str)
  local music_fontid = gregosheet.music_fontid
  local std_delimiter_sequence_width_sp = measure_width_sp(std_delimiter_sequence, music_fontid)

  local tokens = {}
  local note_group = ""
  local last_type = nil

  for char in str:gmatch(".") do
    if char:match(notes) then
      note_group = note_group .. char
      last_type = "note"
    elseif char:match(delimiters) then
      if note_group ~= "" then
        table.insert(tokens, {type = "note", value = note_group, width_sp = measure_width_sp(note_group, music_fontid)})
        note_group = ""
      end
      if last_type ~= "delimiter" then
        table.insert(tokens, {type = "delimiter", value = std_delimiter_sequence, width_sp = std_delimiter_sequence_width_sp})
      end
      last_type = "delimiter"
    elseif char:match(symbols) then
      if note_group ~= "" then
        table.insert(tokens, {type = "note", value = note_group, width_sp = measure_width_sp(note_group, music_fontid)})
        note_group = ""
      end
      table.insert(tokens, {type = "symbol", value = char, width_sp = measure_width_sp(char, music_fontid)})
      last_type = "symbol"
    end
  end

  if note_group ~= "" then
    table.insert(tokens, {type = "note", value = note_group, width_sp = measure_width_sp(note_group, music_fontid)})
  end

  return tokens
end

-- Parse lyrics into syllables with metadata
local function parse_lyrics(str)
  local syllables = {}
  local i = 1

  while i <= #str do
    local char = str:sub(i, i)

    if char == " " then
      i = i + 1
    elseif char == "-" then
      i = i + 1
    else
      -- Extract syllable
      local syllable = ""
      while i <= #str and str:sub(i, i) ~= " " and str:sub(i, i) ~= "-" do
        syllable = syllable .. str:sub(i, i)
        i = i + 1
      end

      -- Check if next non-space character is hyphen or end of string
      local word_end = (i > #str or str:sub(i, i) == " ")

      table.insert(syllables, {
        type = "lyric",
        text = syllable,
        word_end = word_end,
        width_sp = measure_width_sp(syllable, gregosheet.lyrics_fontid)
      })
    end
  end

  return syllables
end

-- Calculate free space between previous and current lyric
local function calculate_free_space(prev_pos, prev_after_width, curr_pos, curr_before_width)
  if not prev_pos then return nil end
  local prev_right = prev_pos + prev_after_width
  local curr_left = curr_pos - curr_before_width
  return curr_left - prev_right
end

function gregosheet.render(clef, melody, lyrics)
  -- Check if music fits on page
  local text_width = tex.dimen["textwidth"]
  local music_width = clef.width_sp
  for i, token in ipairs(melody) do
    music_width = music_width + token.width_sp
  end

  if music_width > text_width then
    texio.write_nl("WARNING: Music width " .. music_width .. "sp exceeds text width " .. text_width .. "sp by " .. (music_width - text_width) .. "sp")
  end

  tex.sprint("\\noindent")

  -- Create music hbox
  tex.sprint("\\hbox{")
  tex.sprint("\\fontsize{20}{24}\\selectfont\\MusicFont")
  tex.sprint(clef.value)
  texio.write_nl("\n=== MELODY ===")
  texio.write_nl(string.format("Clef at 0, width=%d", clef.width_sp))

  local melody_pos = clef.width_sp
  for i, token in ipairs(melody) do
    if token.type == "note" then
      texio.write_nl(string.format("Note %d at %d", i, melody_pos))
    end
    tex.sprint(token.value)
    melody_pos = melody_pos + token.width_sp
  end
  tex.sprint("}")

  -- Create lyrics line with absolute positioning
  tex.sprint("\\vskip2pt")
  tex.sprint("\\hbox to 0pt{")
  tex.sprint("\\fontsize{10}{12}\\selectfont\\LyricFont")
  texio.write_nl("\n=== LYRICS ===")

  for i, lyric in ipairs(lyrics) do
    if lyric.start_sp then
      texio.write_nl(string.format("Lyric %d '%s' at %.0f", i, lyric.text, lyric.start_sp))
      -- Position each lyric absolutely using \hbox to 0pt and \hskip
      tex.sprint("\\hbox to 0pt{")
      tex.sprint("\\hskip" .. lyric.start_sp .. "sp")
      tex.sprint(lyric.text)
      tex.sprint("\\hss}")
    end
  end

  tex.sprint("\\hss}")
end

-- Calculate the starting position for a lyric under a note
local function calculate_lyric_starting_position(lyric, token, music_pos_sp)
  if lyric.width_sp >= token.width_sp and not token.value:match(recited_notes) then
    -- Center lyric under note
    return music_pos_sp + (token.width_sp / 2) - (lyric.width_sp / 2)
  else
    -- Lyrics should align to the left edge of the note group
    return music_pos_sp
  end
end

-- Get minimal delimiter combination wider than distance_sp
local function get_delimiter_for_distance(distance_sp)
  local music_fontid = gregosheet.music_fontid
  local w_s = measure_width_sp(delimiter_s, music_fontid)
  local w_m = measure_width_sp(delimiter_m, music_fontid)
  local w_l = measure_width_sp(delimiter_l, music_fontid)

  -- Use as many large delimiters as possible
  local n_l = math.floor(distance_sp / w_l)
  local remaining = distance_sp - n_l * w_l

  if remaining <= 0 then
    return string.rep(delimiter_l, n_l + 1)
  end

  -- Check combinations with minimal count
  if remaining < w_s then
    return string.rep(delimiter_l, n_l) .. delimiter_s
  elseif remaining < w_m then
    -- Compare: l+s vs m
    if w_s > remaining then
      return string.rep(delimiter_l, n_l) .. delimiter_s
    else
      return string.rep(delimiter_l, n_l) .. delimiter_m
    end
  elseif remaining < w_l then
    -- Try: l+m, l+s, m+s, or just add another l
    if w_m > remaining then
      return string.rep(delimiter_l, n_l) .. delimiter_m
    elseif w_m + w_s > remaining then
      return string.rep(delimiter_l, n_l) .. delimiter_m .. delimiter_s
    else
      return string.rep(delimiter_l, n_l + 1)
    end
  end

  return string.rep(delimiter_l, n_l + 1)
end

-- Extract clef from melody tokens
local function extract_clef(melody)
  local music_fontid = gregosheet.music_fontid
  local clef_value = ""

  while #melody > 0 and melody[1].type ~= "note" do
    local token = table.remove(melody, 1)
    if token.type == "symbol" then
      clef_value = clef_value .. token.value
    end
  end

  clef_value = clef_value .. "-"

  return {
    type = "symbol",
    value = clef_value,
    width_sp = measure_width_sp(clef_value, music_fontid)
  }
end

local function find_last_delimiter_index(melody, current_index)
  for j = current_index - 1, 1, -1 do
    if melody[j].type == "delimiter" then
      return j
    end
  end
  return nil
end

local function get_or_insert_last_delimiter(melody, current_index)
  local last_delimiter_index = find_last_delimiter_index(melody, current_index)

  if not last_delimiter_index then
    -- Insert empty delimiter before current note
    table.insert(melody, current_index, {type = "delimiter", value = "", width_sp = 0})
    last_delimiter_index = current_index
  end

  return last_delimiter_index, melody[last_delimiter_index]
end

function spacing_compute(melody, lyrics)
  local space_width_sp = measure_width_sp(" ", gregosheet.lyrics_fontid)
  local hyphen_width_sp = measure_width_sp("-", gregosheet.lyrics_fontid)

  local clef = extract_clef(melody)

  local music_pos_sp = clef.width_sp
  local lyric_index = 1
  local i = 1

  while i <= #melody do
    local token = melody[i]
    if token.type == "note" then
      local lyric = lyrics[lyric_index]
      if lyric then
        lyric.start_sp = calculate_lyric_starting_position(lyric, token, music_pos_sp)

        -- Check if lyrics overlap or have gap
        local previous_lyric = lyrics[lyric_index - 1]
        if previous_lyric then
          -- Calculate gap between previous lyric end and current lyric start
          local prev_end_sp = previous_lyric.start_sp + previous_lyric.width_sp
          if previous_lyric.word_end then
            prev_end_sp = prev_end_sp + space_width_sp
          end
          local gap_sp = lyric.start_sp - prev_end_sp

          if gap_sp < 0 then
            -- Lyrics overlap, need to add delimiter width
            local needed_extra_space_sp = -gap_sp

            -- Find the last delimiter token before current note
            local last_delimiter_index, last_delimiter = get_or_insert_last_delimiter(melody, i)

            local needed_delimiter_width_sp = last_delimiter.width_sp + needed_extra_space_sp

            -- Get appropriate delimiter combination for the needed width
            local last_delimiter_old_width_sp = last_delimiter.width_sp
            last_delimiter.value = get_delimiter_for_distance(needed_delimiter_width_sp)
            last_delimiter.width_sp = measure_width_sp(last_delimiter.value, gregosheet.music_fontid)

            -- Recalculate music position and lyric position
            music_pos_sp = music_pos_sp + (last_delimiter.width_sp - last_delimiter_old_width_sp)
            lyric.start_sp = calculate_lyric_starting_position(lyric, token, music_pos_sp)
          end
        end

        -- Hyphenation
        if previous_lyric and not previous_lyric.word_end then
          gap_sp = lyric.start_sp - (previous_lyric.start_sp + previous_lyric.width_sp)
          if gap_sp > tolerable_syllabel_gap_sp then
            if gap_sp < hyphen_width_sp then
              -- Find the last delimiter token before current note
              local last_delimiter_index, last_delimiter = get_or_insert_last_delimiter(melody, i)

              local last_delimiter_old_width_sp = last_delimiter.width_sp
              needed_delimiter_width_sp = last_delimiter.width_sp + hyphen_width_sp - gap_sp
              last_delimiter.value = get_delimiter_for_distance(needed_delimiter_width_sp)
              last_delimiter.width_sp = measure_width_sp(last_delimiter.value, gregosheet.music_fontid)

              music_pos_sp = music_pos_sp + (last_delimiter.width_sp - last_delimiter_old_width_sp)
              lyric.start_sp = calculate_lyric_starting_position(lyric, token, music_pos_sp)
              gap_sp = lyric.start_sp - (previous_lyric.start_sp + previous_lyric.width_sp)
            end

            table.insert(lyrics, lyric_index, {
              type = "hyphen",
              text = "-",
              width_sp = hyphen_width_sp,
              start_sp = lyric.start_sp - hyphen_width_sp - (gap_sp - hyphen_width_sp) / 2
            })
            lyric_index = lyric_index + 1
          end
        end

        -- If the lyric ends a word, mark it (space added in render or here)
        if lyric.word_end then
          lyric.text = lyric.text .. " "
          lyric.width_sp = lyric.width_sp + space_width_sp
        end

        lyric_index = lyric_index + 1
      end
    end
    music_pos_sp = music_pos_sp + token.width_sp
    i = i + 1
  end

  return clef
end

function gregosheet.main(melody_str, lyrics_str)
  local melody = parse_melody(melody_str)
  local lyrics = parse_lyrics(lyrics_str)

  local clef = spacing_compute(melody, lyrics)

  gregosheet.render(clef, melody, lyrics)
end
