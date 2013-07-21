class String
  def snake
    underscore.gsub(/\s+/, '_')
  end
  
  def word_count
    scan(/[\w-]+/).size
  end
  
  def excerpt(i, j, size)
    chars_available = size - (j - i)
    begin_at = [i - chars_available / 2, 0].max
    chars_available = chars_available - (i - begin_at)
    go_to = j + chars_available
    self[/.{#{begin_at}}\b(\S.{0,#{go_to - 1}}\W)/, 1] || ''
  end
end
