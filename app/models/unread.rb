class Unread < ActiveRecord::Base
  belongs_to :post
  belongs_to :user
  
  validates_presence_of :post
  validates_presence_of :user
  
  validates_uniqueness_of :user_id, :scope => :post_id
  after_create :cache_published
  
  def self.for_feed(feed_id)
    where(["feed_id = ?", feed_id])
  end
  
  def self.shared
    where(shared: true)
  end
  
  def self.unshared
    where(shared: false)
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
  
  def cache_published
    update_attribute(:published, post.published)
  end
end
