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
  after_save :reindex!
  before_destroy :remove_from_index!
  before_save :clean_title
  
  include Tire::Model::Search
  
  mapping do
    indexes :id, type: 'integer'
    indexes :original_post_id, type: 'integer'
    indexes :feed_id, type: 'integer'
    indexes :feed_name
    indexes :comment
    indexes :comment_count, type: 'integer'
    indexes :title, boost: 10
    indexes :content
    indexes :author
    indexes :published, type: 'date'
    indexes :url
    indexes :shared, type: 'boolean'
    indexes :note, boost: 5
    indexes :reader_id
    indexes :user
  end
  
  def self.search(user, params)
    tire.search(page: params[:page].to_i || 1) do
      query { string params[:query], default_operator: "AND"} if params[:query].present?
      filter :or, user.subscriptions_as_array_of_hashes
      highlight :title, :comment, :content, :note, options: {tag: '<strong class="search-highlight">', number_of_fragments: 0}
    end
  end
  
  def self.delete_old_posts
    has_no_unreads.unshared.where(["published < ?", 3.months.ago]).delete_all
  end
  
  def self.has_no_unreads
    where("(SELECT count(1) FROM unreads u WHERE u.post_id = posts.id) = 0")
  end
  
  def reindex!
    Post.delay.perform_reindex!(id)
  end

  def self.perform_reindex!(post_id)
    Post.find(post_id).tire.update_index
  end
  
  def remove_from_index!
    self.index.remove self
  end
  
  def comment_count
    comments.count
  end
  
  def visible_to
    feed.subscriptions.map(&:user_id)
  end
  
  def to_indexed_json
    to_json(methods: [:comment, :user, :comment_count, :feed_name])
  end
  
  def feed_name
    feed.title
  end
  
  def user
    sharer.try(:name)
  end
  
  def comment
    comments.map { |c| c.to_partial }.join("\n")
  end
  
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
  
  def self.reader
    where("reader_id IS NOT NULL")
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
  
  def self.most_discussed_in_period(period, limit)
    candidates = shared.where(["created_at > ?", (period * 4).ago])
    threads = candidates.sort_by do |post|
      -1 * (1000 * post.thread_participants(period).size + post.comments.where(["created_at > ?", period.ago]).sum(&:word_count))
    end.first(limit)
  end
  
  def thread_participants(period = nil)
    if period
      ([sharer] | comments.where(["created_at > ?", period.ago]).map(&:user)).uniq
    else
      ([sharer] | comments.map(&:user)).uniq
    end
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
  
  def share_url
    "http:#{Domain.url}#{path}"
  end
  
  def share_url_with_email_token(user)
    "http:#{Domain.url}#{path}?email_token=#{user.share_token.first(10)}"
  end
  
  def path
    "/reader/posts/#{id}"
  end
  
  def note_word_count
    return 0 if note.nil?
    renderer = Redcarpet::Markdown.new(HTMLwithPygmentsAndTargetBlankAutolinks, autolink: true, fenced_code_blocks: true)
    Sanitize.clean(renderer.render(note), elements: ['p', 'span', 'a', 'b', 'em', 'strong', 'i'], remove_contents: true).word_count
  end

  def to_partial(is_unread = true)
    view = ActionView::Base.new(ActionController::Base.view_paths, {})
    view.extend ApplicationHelper
    view.extend ReaderHelper
    view.render(partial: "reader/entry", locals: {entry: self, index: id, is_unread: is_unread})
  end
  
  def absolutize_relative_image_paths!
    new_content = "" + content
    doc = Nokogiri::HTML(content)
    doc.css("img").each do |image|
      image_url = image['src']
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
    
    mentionable_text = url.starts_with?("#quickpost-") ? content : note
    
    mentioned_users = []
    Mentions.get(mentionable_text).each do |mention|
      recipient = User.find_by_fingerprint(mention[:fingerprint])
      if !mentioned_users.include?(recipient)
        mentioned_users << recipient
        excerpt = mentionable_text.excerpt(mention[:indices][0], mention[:indices][1], 60).strip
        ShareMailer.share_email(recipient, self, mentioned: {excerpt: "..#{excerpt}.."}).deliver
      end
    end
    
    (feed.users - mentioned_users).each do |recipient|
      ShareMailer.share_email(recipient, self, mentioned: false).deliver
    end
  end
  
  def clean_title
    self.title = HTMLEntities.new.decode(title)
  end
end
