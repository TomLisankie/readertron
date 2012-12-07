class String
  def snake
    underscore.gsub(/\s+/, '_')
  end
end
