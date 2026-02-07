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
local symbols = "[¼ÿ®−§'\"+!%%/=()ÖÜÓ%sM>#&@{}<¿À]"
local barlines = "[,.?:;]"

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
    elseif char:match(barlines) then
      if note_group ~= "" then
        table.insert(tokens, {type = "note", value = note_group, width_sp = measure_width_sp(note_group, music_fontid)})
        note_group = ""
      end
      table.insert(tokens, {type = "barline", value = char, width_sp = measure_width_sp(char, music_fontid)})
      last_type = "barline"
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

function gregosheet.render(systems)
  for sys_idx, system in ipairs(systems) do
    tex.sprint("\\noindent")

    -- Create music hbox
    tex.sprint("\\hbox{")
    tex.sprint("\\fontsize{20}{24}\\selectfont\\MusicFont")
    tex.sprint(system.clef.value)

    for i, token in ipairs(system.melody) do
      tex.sprint(token.value)
    end
    tex.sprint("}")

    -- Create lyrics line with absolute positioning
    tex.sprint("\\vskip2pt")
    tex.sprint("\\hbox to 0pt{")
    tex.sprint("\\fontsize{10}{12}\\selectfont\\LyricFont")

    for i, lyric in ipairs(system.lyrics) do
      if lyric.start_sp then
        tex.sprint("\\hbox to 0pt{")
        tex.sprint("\\hskip" .. lyric.start_sp .. "sp")
        tex.sprint(-2, lyric.text)
        tex.sprint("\\hss}")
      end
    end

    tex.sprint("\\hss}")

    if sys_idx < #systems then
      tex.sprint("\\vskip10pt")
    end
  end
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
local function get_minimal_delimiter_over_distance(distance_sp)
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

-- Get maximal delimiter combination smaller than distance_sp
local function get_maximal_delimiter_under_distance(distance_sp)
  local music_fontid = gregosheet.music_fontid
  local w_s = measure_width_sp(delimiter_s, music_fontid)
  local w_m = measure_width_sp(delimiter_m, music_fontid)
  local w_l = measure_width_sp(delimiter_l, music_fontid)

  if distance_sp <= 0 then
    return ""
  end

  local n_l = math.floor(distance_sp / w_l)
  local remaining = distance_sp - n_l * w_l
  local n_m = math.floor(remaining / w_m)
  remaining = remaining - n_m * w_m
  local n_s = math.floor(remaining / w_s)

  return string.rep(delimiter_l, n_l) .. string.rep(delimiter_m, n_m) .. string.rep(delimiter_s, n_s)
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

local function find_last_token_with_type(melody, current_index, token_type)
  for j = current_index - 1, 1, -1 do
    if melody[j].type == token_type then
      return j
    end
  end
  return nil
end

local function get_or_insert_last_delimiter(melody, current_index)
  local last_delimiter_index = find_last_token_with_type(melody, current_index, "delimiter")

  if not last_delimiter_index then
    -- Insert empty delimiter before current note
    table.insert(melody, current_index, {type = "delimiter", value = "", width_sp = 0})
    last_delimiter_index = current_index
  end

  return last_delimiter_index, melody[last_delimiter_index]
end

local function is_lyric_overful(lyric)
  return lyric.start_sp + lyric.width_sp > tex.dimen["textwidth"]
end

function spacing_compute(melody, lyrics)
  local space_width_sp = measure_width_sp(" ", gregosheet.lyrics_fontid)
  local hyphen_width_sp = measure_width_sp("-", gregosheet.lyrics_fontid)
  local page_width_sp = tex.dimen["textwidth"]

  texio.write_nl("\n=== SPACING_COMPUTE START ===")
  texio.write_nl(string.format("page_width_sp=%.1f", page_width_sp))

  local clef = extract_clef(melody)

  local systems = {}
  local system = {clef = clef, melody = {}, lyrics = {}}
  local last_token = nil
  local music_pos_sp = clef.width_sp
  local lyric_index = 1
  local i = 1

  while i <= #melody do
    local token = melody[i]
    local last_token = melody[i - 1]
    local lyric_overful = false

    texio.write_nl(string.format("[i=%d] %s, pos=%.1f, lyric_idx=%d", i, token.type, music_pos_sp, lyric_index))

    if token.type == "barline" then
      -- There are fixed delimiters around barlines
      if last_token and last_token.type == "delimiter" then
        last_token.value = "-"
        music_pos_sp = music_pos_sp - last_token.width_sp + hyphen_width_sp
        last_token.width_sp = hyphen_width_sp
      end
      local next_token = melody[i + 1]
      if next_token and next_token.type == "delimiter" then
        next_token.value = "--"
        next_token.width_sp = hyphen_width_sp
      end
    end

    local lyric = lyrics[lyric_index]
    if lyric and (token.type == "note" or (token.type == "barline" and lyric.text == "*")) then
      lyric.start_sp = calculate_lyric_starting_position(lyric, token, music_pos_sp)
      texio.write_nl(string.format("  Lyric '%s' @ %.1f", lyric.text, lyric.start_sp))

      -- Check if lyrics overlap or have gap
      local previous_lyric = system.lyrics[#system.lyrics]
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
          last_delimiter.value = get_minimal_delimiter_over_distance(needed_delimiter_width_sp)
          last_delimiter.width_sp = measure_width_sp(last_delimiter.value, gregosheet.music_fontid)

          -- Recalculate music position and lyric position
          music_pos_sp = music_pos_sp + (last_delimiter.width_sp - last_delimiter_old_width_sp)
          lyric.start_sp = calculate_lyric_starting_position(lyric, token, music_pos_sp)
        end
      end

      lyric_overful = is_lyric_overful(lyric)
      if lyric_overful then
        texio.write_nl(string.format("  OVERFUL: lyric end=%.1f > page=%.1f", lyric.start_sp + lyric.width_sp, page_width_sp))
      end

      -- Hyphenation
      if previous_lyric and not previous_lyric.word_end then
        if not lyric_overful then
          gap_sp = lyric.start_sp - (previous_lyric.start_sp + previous_lyric.width_sp)
          if gap_sp > tolerable_syllabel_gap_sp then
            if gap_sp < hyphen_width_sp then
              -- Find the last delimiter token before current note
              local last_delimiter_index, last_delimiter = get_or_insert_last_delimiter(melody, i)

              local last_delimiter_old_width_sp = last_delimiter.width_sp
              needed_delimiter_width_sp = last_delimiter.width_sp + hyphen_width_sp - gap_sp
              last_delimiter.value = get_minimal_delimiter_over_distance(needed_delimiter_width_sp)
              last_delimiter.width_sp = measure_width_sp(last_delimiter.value, gregosheet.music_fontid)

              music_pos_sp = music_pos_sp + (last_delimiter.width_sp - last_delimiter_old_width_sp)
              lyric.start_sp = calculate_lyric_starting_position(lyric, token, music_pos_sp)
              gap_sp = lyric.start_sp - (previous_lyric.start_sp + previous_lyric.width_sp)
            end

            table.insert(system.lyrics, {
              type = "hyphen",
              text = "-",
              width_sp = hyphen_width_sp,
              start_sp = lyric.start_sp - hyphen_width_sp - (gap_sp - hyphen_width_sp) / 2
            })
          end
        else
          previous_lyric.text = previous_lyric.text .. "-"
          previous_lyric.width_sp = measure_width_sp(previous_lyric.text, gregosheet.lyrics_fontid)
        end
      end

      -- If the lyric ends a word, mark it (space added in render or here)
      if lyric.word_end then
        lyric.text = lyric.text .. " "
        lyric.width_sp = lyric.width_sp + space_width_sp
      end
    end

    -- System handling
    if music_pos_sp + token.width_sp > page_width_sp or lyric_overful then
      texio.write_nl(string.format("  OVERFLOW: pos+token=%.1f > page=%.1f, lyric_overful=%s", music_pos_sp + token.width_sp, page_width_sp, tostring(lyric_overful)))
      local gap_to_page_end_sp = page_width_sp - music_pos_sp
      if last_token and last_token.type == "note" then
        local delimiter_value = get_maximal_delimiter_under_distance(gap_to_page_end_sp)
        local delimiter_width_sp = measure_width_sp(delimiter_value, gregosheet.music_fontid)
        if token.type ~= "delimiter" then
          table.insert(system.melody, {
            type = "delimiter",
            value = delimiter_value,
            width_sp = delimiter_width_sp,
            start_sp = music_pos_sp
          })
        end
      elseif last_token and last_token.type == "delimiter" then
        last_token.value = get_maximal_delimiter_under_distance(gap_to_page_end_sp)
        last_token.width_sp = measure_width_sp(last_token.value, gregosheet.music_fontid)
      elseif last_token and last_token.type == "barline" then
        -- The delimiter before the barline should push the barline to the end of the system
        local last_delimiter_index, last_delimiter = get_or_insert_last_delimiter(melody, i - 1)
        local last_delimiter_old_width_sp = last_delimiter.width_sp
        needed_delimiter_width_sp = last_delimiter.width_sp + gap_to_page_end_sp
        last_delimiter.value = get_maximal_delimiter_under_distance(needed_delimiter_width_sp)
        last_delimiter.width_sp = measure_width_sp(last_delimiter.value, gregosheet.music_fontid)
      elseif last_token and last_token.type == "symbol" then
        -- The delimiter before the symbol should push the symbol to the next system as well
        local last_delimiter_index, last_delimiter = get_or_insert_last_delimiter(melody, i - 1)
        local last_delimiter_old_width_sp = last_delimiter.width_sp
        needed_delimiter_width_sp = last_delimiter.width_sp + gap_to_page_end_sp + token.width_sp
        last_delimiter.value = get_maximal_delimiter_under_distance(needed_delimiter_width_sp)
        last_delimiter.width_sp = measure_width_sp(last_delimiter.value, gregosheet.music_fontid)
      end

      if token.type == "delimiter" then
        token.value = get_maximal_delimiter_under_distance(gap_to_page_end_sp)
        token.width_sp = measure_width_sp(token.value, gregosheet.music_fontid)
        table.insert(system.melody, token)
      elseif token.type == "barline" then
        local last_note_index = find_last_token_with_type(system.melody, #system.melody, "note")
        if last_note_index then
          local cumulative_width_sp = 0
          if last_note_index then
            for j = #system.melody, last_note_index, -1 do
              cumulative_width_sp = cumulative_width_sp + system.melody[j].width_sp
              table.remove(system.melody, j)
            end
          end
          local new_delimiter_value = get_maximal_delimiter_under_distance(gap_to_page_end_sp + cumulative_width_sp)
          local new_delimiter_width_sp = measure_width_sp(new_delimiter_value, gregosheet.music_fontid)
          table.insert(system.melody, {
            type = "delimiter",
            value = new_delimiter_value,
            width_sp = new_delimiter_width_sp,
            start_sp = music_pos_sp
          })
          i = find_last_token_with_type(melody, i, "note")
        end
      end

      -- Start new system
      texio.write_nl(string.format("  Starting new system %d, resetting music_pos_sp to %.1f", #systems + 1, clef.width_sp))
      table.insert(systems, system)
      system = {clef = clef, melody = {}, lyrics = {}}
      music_pos_sp = clef.width_sp
    else
      texio.write_nl("  Fits, adding token")
      table.insert(system.melody, token)
      if lyric and lyric.start_sp then
        texio.write_nl(string.format("  Adding lyric '%s'", lyric.text))
        table.insert(system.lyrics, lyric)
        lyric_index = lyric_index + 1
      end
      music_pos_sp = music_pos_sp + token.width_sp
      i = i + 1
    end
  end

  table.insert(systems, system)
  texio.write_nl(string.format("\n=== END: %d systems ===", #systems))

  return systems
end

function gregosheet.main(melody_str, lyrics_str)
  local melody = parse_melody(melody_str)
  local lyrics = parse_lyrics(lyrics_str)

  local systems = spacing_compute(melody, lyrics)

  gregosheet.render(systems)
end
