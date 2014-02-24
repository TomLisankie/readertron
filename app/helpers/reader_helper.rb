module ReaderHelper
  def pretty_date(date)
    return '' unless date
    
    date.in_eastern_time.strftime("%b #{date.in_eastern_time.day}, %Y %I:%M %p")
  end
  
  def star_class(post)
    # if (share = Post.find_all_by_original_post_id(post.id).select {|share| share.feed.title == current_user.name}.first.presence)
    #   return "star-active" if share.note.blank?
    # end
    "star-inactive"
  end
  
  def share_with_note_class(post)
    # if (share = Post.find_all_by_original_post_id(post.id).select {|share| share.feed.title == current_user.name}.first.presence)
    #   return "share-with-note-active" if share.note.present?
    # end
    "share-with-note-inactive"
  end
  
  def feed_favicon(feed_id)
    if File.exists?("#{Rails.root}/app/assets/images/favicons/#{feed_id}.png")
      "/assets/favicons/#{feed_id}.png"
    else
      "/assets/favicons/default.png"
    end
  end
end
