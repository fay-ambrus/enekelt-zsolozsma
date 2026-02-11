gregosheet_psalm = gregosheet_psalm or {}

local function total_syllables(wsc)
  local total = 0
  for _, count in ipairs(wsc) do
    total = total + count
  end
  return total
end

local function is_word_start_from_back(wsc, syllable_idx)
  local cumulative = 0
  for i = #wsc, 1, -1 do
    cumulative = cumulative + wsc[i]
    if cumulative == syllable_idx then
      return true
    elseif cumulative > syllable_idx then
      return false
    end
  end
  return false
end

-- Returns: underline_list, slash_idx
function gregosheet_psalm.mark_flexa(wsc, tone, initium)
  local underline, slash = {}, nil

  -- Initium
  if initium then
    if tone == "tonus-pregrinus" then
      table.insert(underline, 1)
    elseif wsc[1] == 1 and wsc[2] and wsc[2] ~= 1 then
      table.insert(underline, 1)
    end
  end

  -- Flexa
  table.insert(underline, total_syllables(wsc))

  return underline, slash
end

function gregosheet_psalm.mark_mediatio(wsc, tone, initium)
  local underline, slash = {}, nil
  local total = total_syllables(wsc)

  -- Initium
  if initium then
    if tone == "tonus-pregrinus" then
      table.insert(underline, 1)
    elseif wsc[1] == 1 and wsc[2] and wsc[2] ~= 1 then
      table.insert(underline, 1)
    end
  end

  -- Mediatio
  if tone == "1" or tone == "2" or tone == "5" or tone == "tonus-irregularis" then
    if is_word_start_from_back(wsc, 3) and not is_word_start_from_back(wsc, 2) then
      slash = total - 3
    else
      slash = total - 2
    end

  elseif tone == "3" then
    slash = total - 2

  elseif tone == "4" or tone == "7" or tone == "8" or tone == "tonus-peregrinus"then
    if is_word_start_from_back(wsc, 3) and not is_word_start_from_back(wsc, 2) then
      slash = total - 3
      table.insert(underline, total - 4)
    else
      slash = total - 2
      table.insert(underline, total - 3)
    end

  elseif tone == "6" then
    if is_word_start_from_back(wsc, 3) and not is_word_start_from_back(wsc, 2) then
      slash = total - 3
      table.insert(underline, total - 3)
    else
      slash = total - 2
      table.insert(underline, total - 2)
    end
  end
  return underline, slash
end

function gregosheet_psalm.mark_terminatio(wsc, tone)
  local underline, slash = {}, nil
  local total = total_syllables(wsc)

  if tone == "1" or tone == "4" or tone == "6" or tone == "7" or tone == "8" or tone == "tonus-irregularis" then
    if is_word_start_from_back(wsc, 3) and not is_word_start_from_back(wsc, 2) then
      slash = total - 3
      table.insert(underline, total - 4)
    else
      slash = total - 2
      table.insert(underline, total - 3)
    end

  elseif tone == "2" then
    slash = total - 2

  elseif tone == "3" then
    if is_word_start_from_back(wsc, 3) and not is_word_start_from_back(wsc, 2) then
      slash = total - 3
      table.insert(underline, total - 3)
    else
      slash = total - 2
      table.insert(underline, total - 2)
    end

  elseif tone == "5" or tone == "tonus-peregrinus" then
    -- Slash
    if is_word_start_from_back(wsc, 3) and not is_word_start_from_back(wsc, 2) then
      slash = total - 3
    else
      slash = total - 2
    end

    -- Underline
    if is_word_start_from_back(wsc, total - slash + 3) and not is_word_start_from_back(wsc, total - slash + 2) then
      table.insert(underline, slash - 2)
    else
      table.insert(underline, slash - 1)
    end
  end
  return underline, slash
end
