class Post < ActiveRecord::Base
  belongs_to :feed
  has_many :unreads, dependent: :destroy
  has_many :comments, dependent: :destroy
  
  validates_uniqueness_of :url, unless: ->(post) { post.shared? }
  validate :not_a_shady_duplicate
  validates_presence_of :url
  validates_presence_of :title
  validates_presence_of :published
  validates_presence_of :content
  
  after_create :generate_unreads, :cache, :absolutize_relative_image_paths!
  
  def self.for_user(user)
    joins("JOIN feeds ON feeds.id = posts.feed_id JOIN subscriptions ON feeds.id = subscriptions.feed_id")
      .where("subscriptions.user_id = #{user.id}")
  end
  
  def self.for_feed(feed_id)
    joins("JOIN feeds ON feeds.id = posts.feed_id").where("feeds.id = #{feed_id}")
  end
  
  def self.chron
    order("published ASC")
  end
  
  def self.revchron
    order("published DESC")
  end
  
  def self.revshared
    order("created_at DESC")
  end
  
  def self.unread_for_user(user)
    joins("JOIN unreads ON posts.id = unreads.post_id").where("unreads.user_id = #{user.id}")
  end

  def self.unread_for_options(user, date_sort, page=0, feed_id=nil)
    share_town = (feed_id == "shared" || (feed_id.present? && Feed.find(feed_id).shared?))
    
    if page == 0
      if feed_id.present?
        unreads = feed_id == "shared" ? user.unreads.shared : user.unreads.for_feed(feed_id)
      else
        unreads = user.unreads.unshared
      end
      
      unreads = case date_sort
      when "chron"
        unreads.chron
      when "revchron"
        unreads.revchron
      when "revshared"
        unreads.revshared
      end

      Rails.cache.write("#{user.id}_#{feed_id}_#{date_sort}", unreads.map(&:post_id))
      if (unreads.first && unreads.first.shared?)
        return unreads.first(10).map(&:post)
      else
        return cached(unreads.first(10).map(&:post_id))
      end
    else
      post_ids = Rails.cache.read("#{user.id}_#{feed_id}_#{date_sort}")
      if post_ids
        if share_town
          posts = Post.find(Array.wrap(post_ids[page * 10..(page * 10) + 9]))
        else
          posts = cached(Array.wrap(post_ids[page * 10..(page * 10) + 9]))
        end
      else
        posts = []
      end
      return posts
    end
  end
  
  def self.for_options(user, date_sort, page=0, feed_id=nil)
    if feed_id.present?
      posts = feed_id == "shared" ? shared.for_user(user) : for_feed(feed_id)
    else
      posts = unshared.for_user(user)
    end
    
    posts = case date_sort
    when "chron"
      posts.chron
    when "revchron"
      posts.revchron
    when "revshared"
      posts.revshared
    end
    
    return posts.offset(page.to_i * 10).limit(10)
  end
  
  def self.shared
    where("posts.shared = ?", true)
  end
  
  def self.unshared
    where("posts.shared = ?", false)
  end

  def self.cached(ids)
    ids.map {|id| Rails.cache.fetch("post-#{id}") { Post.find(id).to_partial(:unread) } }
  end
  
  def self.send_share_emails(id)
    find(id).send_share_emails
  end
  
  def refresh(attrs)
    update_attributes(attrs)
    shared_posts = Post.find_all_by_original_post_id(id).each do |share|
      share.update_attributes(attrs)
    end
  end
  
  def generate_unreads
    feed.users.each do |subscriber|
      subscriber.unreads.create(post: self, feed_id: self.feed_id, shared: self.shared?)
    end
  end
  
  def unread_for_user?(user)
    unreads.find_by_user_id(user.id).present?
  end
  
  def sharer
    User.find_by_name(feed.title) if shared?
  end
  
  def not_a_shady_duplicate
    if Post.last
      feed.posts.where(published: Post.last.published, title: Post.last.title).empty?
    end
  end

  def cache
    Rails.cache.write("post-#{id}", to_partial, expires_in: 2.weeks) unless shared?
  end

  def to_partial(is_unread = true)
    view = ActionView::Base.new(ActionController::Base.view_paths, {})
    view.extend ApplicationHelper
    view.extend ReaderHelper
    view.render(partial: "reader/entry", locals: {entry: self, index: id, is_unread: is_unread})
  end
  
  def absolutize_relative_image_paths!
    new_content = "" + content
    image_urls = content.scan(/<img.*?src=['"](.*?)['"]/).flatten
    image_urls.each do |image_url|
      begin absolute_image_url = URI.join(url, image_url).to_s rescue next end
      new_content = new_content.gsub(image_url, absolute_image_url)
    end
    if new_content != content
      update_attributes!(content: new_content)
      cache
    end
  end
  
  def send_share_emails
    return unless shared?
    ShareMailer.share_email(feed.users.map(&:email), self).deliver
  end
end
