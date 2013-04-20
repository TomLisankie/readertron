module ApplicationHelper
  
  def urlify_urls(text)
    Rinku.auto_link(text, :all, 'target="_blank"')
  end
  
  def bookmarklet_for_user(user)
    "javascript: (function(){document.body.appendChild(document.createElement('script')).src='#{Domain.url}/reader/bookmarklet.js?token=#{user.share_token}';})();"
  end

  def markdown(text)
    renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
    clean(urlify_urls(renderer.render(text)))
  end
  
  def mdown(text)
    text = text.gsub(%r{(^|\s)([*_])(.+?)\2(\s|$)}x, %{\\1<em>\\3</em>\\4})
    text = text.gsub(/[\n]+/, "<br><br>")
    text = text.gsub("<div>", "<p>").gsub("</div>", "</p>")
    raw(urlify_urls(text))
  end

  def clean_youtube(html)
    sanitize(html, tags: %w(object embed))
  end

  def clean(html)
    raw(Sanitize.clean(html, Sanitize::Config::RELAXED.merge({
                          elements: Sanitize::Config::RELAXED[:elements] + ["style"],
                          remove_contents: ["script", "style"]
                        })).gsub(/<\s*?br\s*?\/?\s*?>/, "<p></p>").gsub("\n\n", "<p></p>"))
  end
  
  def comment_date(date)
    if date >= 1.month.ago
      date.strftime("(#{time_ago_in_words(date)} ago)")
    else
      date.strftime("(%b #{date.day}, %Y %I:%M %p)")
    end
  end
end