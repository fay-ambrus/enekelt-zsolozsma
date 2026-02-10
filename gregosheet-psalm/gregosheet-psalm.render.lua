gregosheet_psalm = gregosheet_psalm or {}

local function underline_vowel(syllable)
  local vowels = "aáeéiíoóöőuúüűAÁEÉIÍOÓÖŐUÚÜŰ"
  for i = 1, utf8.len(syllable) do
    local char = syllable:sub(utf8.offset(syllable, i), utf8.offset(syllable, i+1) - 1)
    if vowels:find(char, 1, true) then
      local before = syllable:sub(1, utf8.offset(syllable, i) - 1)
      local after = syllable:sub(utf8.offset(syllable, i+1))
      return before, char, after
    end
  end
  return syllable, nil, ""
end

local function render_part(text, underline_indices, slash_idx)
  local syllables = gregosheet_psalm.syllabify_hungarian(text)
  local syl_idx = 0
  
  for i, syl in ipairs(syllables) do
    if syl == " " then
      tex.sprint(" ")
    else
      syl_idx = syl_idx + 1
      
      local should_underline = false
      for _, u_idx in ipairs(underline_indices or {}) do
        if u_idx == syl_idx then
          should_underline = true
          break
        end
      end
      
      if should_underline then
        local before, vowel, after = underline_vowel(syl)
        tex.sprint(-2, before)
        if vowel then
          tex.sprint("\\underline{")
          tex.sprint(-2, vowel)
          tex.sprint("}")
        end
        tex.sprint(-2, after)
      else
        tex.sprint(-2, syl)
      end
      
      if slash_idx and slash_idx == syl_idx then
        if i < #syllables and syllables[i+1] == " " then
          tex.sprint(" /")
        else
          tex.sprint("/")
        end
      end
    end
  end
end

function gregosheet_psalm.render(sections_data, continuous, number, title, motto)
  -- Render number if provided
  if number and number ~= "" then
    tex.sprint("\\par\\noindent\\centering")
    tex.sprint("\\fontsize{\\psalmfontsize}{12}\\selectfont\\psalmfont")
    tex.sprint("\\textcolor{red}{")
    tex.sprint(-2, number)
    tex.sprint("}")
    tex.sprint("\\vskip0.5\\blockvskip")
  end
  
  -- Render title if provided
  if title and title ~= "" then
    tex.sprint("\\par\\noindent\\centering")
    tex.sprint("\\fontsize{\\psalmfontsize}{12}\\selectfont\\psalmfont")
    tex.sprint("\\textcolor{red}{")
    tex.sprint(-2, title)
    tex.sprint("}")
    tex.sprint("\\vskip0.5\\blockvskip")
  end
  
  -- Render motto if provided
  if motto and motto ~= "" then
    tex.sprint("\\par\\noindent\\raggedright")
    tex.sprint("\\fontsize{\\psalmfontsize}{12}\\selectfont\\psalmfont")
    -- Find opening parenthesis
    local paren_pos = motto:find("%(")
    if paren_pos then
      local before_paren = motto:sub(1, paren_pos - 1)
      local paren_part = motto:sub(paren_pos)
      tex.sprint("\\textit{")
      tex.sprint(-2, before_paren)
      tex.sprint("}")
      tex.sprint(-2, paren_part)
    else
      tex.sprint("\\textit{")
      tex.sprint(-2, motto)
      tex.sprint("}")
    end
    tex.sprint("\\vskip\\blockvskip")
  end
  
  if continuous then
    tex.sprint("\\par\\noindent\\raggedright")
    tex.sprint("\\fontsize{\\psalmfontsize}{12}\\selectfont\\psalmfont")
    
    for s_idx, section_info in ipairs(sections_data) do
      for i, verse_data in ipairs(section_info.section) do
        if verse_data.number then
          tex.sprint("\\textbf{" .. verse_data.number .. ".} ")
        end
        
        if verse_data.flexa then
          render_part(verse_data.flexa.text, verse_data.flexa.underline, verse_data.flexa.slash)
          tex.sprint(" † ")
        end

        if verse_data.mediatio then
          render_part(verse_data.mediatio.text, verse_data.mediatio.underline, verse_data.mediatio.slash)
          tex.sprint(" * ")
        end

        if verse_data.terminatio then
          render_part(verse_data.terminatio.text, verse_data.terminatio.underline, verse_data.terminatio.slash)
          tex.sprint(" ")
        end
      end
    end
  else
    for s_idx, section_info in ipairs(sections_data) do
      if section_info.is_new_section then
        tex.sprint("\\vskip\\blockvskip")
      end
      
      for i, verse_data in ipairs(section_info.section) do
        tex.sprint("\\par\\noindent")
        tex.sprint("\\fontsize{\\psalmfontsize}{12}\\selectfont\\psalmfont")
        tex.sprint("\\hangindent=0.4in\\hangafter=1")
        
        if verse_data.flexa then
          render_part(verse_data.flexa.text, verse_data.flexa.underline, verse_data.flexa.slash)
          tex.sprint(" †")
          tex.sprint("\\par\\noindent\\hskip0.2in\\hangindent=0.4in\\hangafter=1")
        end

        if verse_data.mediatio then
          render_part(verse_data.mediatio.text, verse_data.mediatio.underline, verse_data.mediatio.slash)
          tex.sprint(" *")
          tex.sprint("\\par\\noindent\\hskip0.2in\\hangindent=0.4in\\hangafter=1")
        end

        if verse_data.terminatio then
          render_part(verse_data.terminatio.text, verse_data.terminatio.underline, verse_data.terminatio.slash)
        end
      end
    end
  end
end
