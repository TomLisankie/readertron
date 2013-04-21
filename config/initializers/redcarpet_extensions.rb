class HTMLwithPygmentsAndTargetBlankAutolinks < Redcarpet::Render::HTML
  def block_code(code, language)
    Pygments.highlight(code, :lexer => language)
  end
  
  def link(link, title, alt_text)
    %(<a target="_blank" href="#{link}">#{alt_text}</a>)
  end
  
  def autolink(link, link_type)
    %(<a target="_blank" href="#{link}">#{link}</a>)
  end
end