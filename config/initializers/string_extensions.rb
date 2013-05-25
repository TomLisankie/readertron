class String
  def snake
    underscore.gsub(/\s+/, '_')
  end
  
  def word_count
    scan(/[\w-]+/).size
  end
end
