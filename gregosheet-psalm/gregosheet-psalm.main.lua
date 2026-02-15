gregosheet_psalm = gregosheet_psalm or {}

local function parse_verse_parts(verse)
  local verse_number = verse:match("^(%d+)%.%s*")
  verse = verse:gsub("^%d+%.%s*", "")
  local parts = {flexa = nil, mediatio = nil, terminatio = nil, number = verse_number}

  local flexa_pos = verse:find("†")
  local mediatio_pos = verse:find("*")

  if flexa_pos and mediatio_pos then
    parts.flexa = verse:sub(1, flexa_pos - 1):match("^%s*(.-)%s*$")
    parts.mediatio = verse:sub(flexa_pos + 3, mediatio_pos - 1):match("^%s*(.-)%s*$")
    parts.terminatio = verse:sub(mediatio_pos + 1):match("^%s*(.-)%s*$")
  elseif mediatio_pos then
    parts.mediatio = verse:sub(1, mediatio_pos - 1):match("^%s*(.-)%s*$")
    parts.terminatio = verse:sub(mediatio_pos + 1):match("^%s*(.-)%s*$")
  else
    parts.terminatio = verse:match("^%s*(.-)%s*$")
  end

  return parts
end

local function get_word_syllable_counts(text)
  local syllables = gregosheet_psalm.syllabify_hungarian(text)
  local word_counts = {}
  local count = 0
  for _, syl in ipairs(syllables) do
    if syl == " " then
      table.insert(word_counts, count)
      count = 0
    else
      count = count + 1
    end
  end
  if count > 0 then table.insert(word_counts, count) end
  return word_counts
end

function gregosheet_psalm.main(text, tone, initium, continuous, number, title, motto, numeral)

  -- Split by section separator (---)
  local sections = {}
  for section in text:gmatch("([^%-%-%-]+)") do
    if section:match("%S") then
      local cleaned = section:match("^%s*(.-)%s*$")
      cleaned = cleaned:gsub("\\par%s*", "")
      table.insert(sections, cleaned)
    end
  end

  local all_verses_data = {}
  for s_idx, section in ipairs(sections) do
    local verses = {}
    for verse in section:gmatch("([^\\]+)") do
      if verse:match("%S") then
        table.insert(verses, verse:match("^%s*(.-)%s*$"))
      end
    end

    local verses_data = {}
    for i, verse in ipairs(verses) do
      local parts = parse_verse_parts(verse)
      local verse_data = {}

      if parts.number then
        verse_data.number = parts.number
      end

      if parts.flexa then
        local counts = get_word_syllable_counts(parts.flexa)
        local underline, slash
        if s_idx == 1 and i == 1 then
          underline, slash = gregosheet_psalm.mark_flexa(counts, tone, true)
        else
          underline, slash = gregosheet_psalm.mark_flexa(counts, tone, initium)
        end
        verse_data.flexa = {text = parts.flexa, underline = underline, slash = slash}
      end

      if parts.mediatio then
        local counts = get_word_syllable_counts(parts.mediatio)
        local underline, slash
        if s_idx == 1 and i == 1 and not parts.flexa then
          underline, slash = gregosheet_psalm.mark_mediatio(counts, tone, true)
        else
          underline, slash = gregosheet_psalm.mark_mediatio(counts, tone, initium)
        end
        verse_data.mediatio = {text = parts.mediatio, underline = underline, slash = slash}
      end

      if parts.terminatio then
        local counts = get_word_syllable_counts(parts.terminatio)
        local underline, slash = gregosheet_psalm.mark_terminatio(counts, tone)
        verse_data.terminatio = {text = parts.terminatio, underline = underline, slash = slash}
      end

      table.insert(verses_data, verse_data)
    end

    table.insert(all_verses_data, {section = verses_data, is_new_section = s_idx > 1})
  end

  gregosheet_psalm.render(all_verses_data, continuous, number, title, motto, numeral)
end
