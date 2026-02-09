gregosheet = gregosheet or {}

function gregosheet.render(systems)
  for sys_idx, system in ipairs(systems) do
    texio.write_nl("=========================================")
    texio.write_nl("System " .. sys_idx)
    texio.write_nl("=========================================")

    tex.sprint("\\noindent")

    -- Create music hbox
    tex.sprint("\\hbox{")
    tex.sprint("\\fontsize{20}{24}\\selectfont\\MusicFont")
    tex.sprint(system.clef.value)

    local current_sp = gregosheet.measure_width_sp(system.clef.value, gregosheet.music_fontid)

    for i, token in ipairs(system.melody) do
      tex.sprint(token.value)
      if token.type == "note" then
        texio.write_nl(string.format("Note: '%s', start_sp=%.0f, center=%.0f", token.value, current_sp, current_sp + gregosheet.measure_width_sp(token.value, gregosheet.music_fontid) / 2))
      end
      current_sp = current_sp + gregosheet.measure_width_sp(token.value, gregosheet.music_fontid)
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
        texio.write_nl(string.format("Lyric: '%s', start_sp=%.0f, center=%.0f", lyric.text, lyric.start_sp, lyric.start_sp + gregosheet.measure_width_sp(lyric.text, gregosheet.lyrics_fontid) / 2))
        tex.sprint("\\hss}")
      end
    end

    tex.sprint("\\hss}")

    if sys_idx < #systems then
      tex.sprint("\\vskip10pt")
    end
  end
end
