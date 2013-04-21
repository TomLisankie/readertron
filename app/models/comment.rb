class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :post
  validates_presence_of :user
  validates_presence_of :post
  validates_presence_of :content
  
  after_create :notify_relevant_users
  
  def notify_relevant_users
    relevant_users = [post.sharer] | post.comments.map(&:user)
    recipients = relevant_users - [user]
    ShareMailer.new_comment_email(recipients.map(&:email), self).deliver
  end
  handle_asynchronously :notify_relevant_users
end