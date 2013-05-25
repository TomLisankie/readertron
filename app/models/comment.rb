class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :post
  validates_presence_of :user
  validates_presence_of :post
  validates_presence_of :content
  
  after_create :notify_relevant_users
  
  def notify_relevant_users
    ShareMailer.new_comment_email(other_thread_participants.map(&:email), self).deliver
  end
  handle_asynchronously :notify_relevant_users
  
  def word_count
    content.word_count
  end
  
  def url
    "http:#{Domain.url}#{path}"
  end
  
  def path
    "/reader/posts/#{post.id}#comment-#{id}"
  end
    
  private
  
  def other_thread_participants
    post.thread_participants - [user]
  end
end