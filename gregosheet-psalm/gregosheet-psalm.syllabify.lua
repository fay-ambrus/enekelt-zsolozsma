gregosheet_psalm = gregosheet_psalm or {}

local function is_vowel(char)
  return char:match("[aáeéiíoóöőuúüűAÁEÉIÍOÓÖŐUÚÜŰ]")
end

local function syllabify_hungarian(text)
  local result = {}
  
  -- Split by spaces to get words
  for word in text:gmatch("%S+") do
    -- Replace digraphs and trigraphs with single tokens
    local clean_word = word:gsub("dzs", "\1")
    clean_word = clean_word:gsub("cs", "\2")
    clean_word = clean_word:gsub("dz", "\3")
    clean_word = clean_word:gsub("gy", "\4")
    clean_word = clean_word:gsub("ly", "\5")
    clean_word = clean_word:gsub("ny", "\6")
    clean_word = clean_word:gsub("sz", "\7")
    clean_word = clean_word:gsub("ty", "\8")
    clean_word = clean_word:gsub("zs", "\9")
    
    -- Convert to array of UTF-8 characters
    local chars = {}
    for p, c in utf8.codes(clean_word) do
      table.insert(chars, utf8.char(c))
    end
    
    local current = ""
    local i = 1
    
    while i <= #chars do
      local char = chars[i]
      current = current .. char
      
      if is_vowel(char) then
        -- Look ahead for consonants before next vowel
        local consonants = ""
        local j = i + 1
        
        while j <= #chars and not is_vowel(chars[j]) do
          consonants = consonants .. chars[j]
          j = j + 1
        end
        
        if consonants == "" then
          table.insert(result, current)
          current = ""
        elseif j > #chars then
          -- End of word: all consonants stay with current syllable
          table.insert(result, current .. consonants)
          current = ""
        else
          -- Multiple consonants between vowels
          local cons_chars = {}
          for p, c in utf8.codes(consonants) do
            table.insert(cons_chars, utf8.char(c))
          end
          if #cons_chars == 1 then
            -- Single consonant goes to next syllable
            table.insert(result, current)
            current = cons_chars[1]
          else
            -- Multiple consonants: all but last stay, last goes to next
            local stay = ""
            for k = 1, #cons_chars - 1 do
              stay = stay .. cons_chars[k]
            end
            table.insert(result, current .. stay)
            current = cons_chars[#cons_chars]
          end
        end
        
        i = j
      else
        i = i + 1
      end
    end
    
    if current ~= "" then
      table.insert(result, current)
    end
    
    -- Add word boundary marker
    table.insert(result, " ")
  end
  
  -- Remove last boundary marker
  if #result > 0 and result[#result] == " " then
    table.remove(result)
  end
  
  -- Restore digraphs and trigraphs
  for i, syl in ipairs(result) do
    if syl ~= " " then
      syl = syl:gsub("\1", "dzs")
      syl = syl:gsub("\2", "cs")
      syl = syl:gsub("\3", "dz")
      syl = syl:gsub("\4", "gy")
      syl = syl:gsub("\5", "ly")
      syl = syl:gsub("\6", "ny")
      syl = syl:gsub("\7", "sz")
      syl = syl:gsub("\8", "ty")
      syl = syl:gsub("\9", "zs")
      result[i] = syl
    end
  end
  
  return result
end

gregosheet_psalm.syllabify_hungarian = syllabify_hungarian
