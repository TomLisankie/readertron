class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :post
  validates_presence_of :user
  validates_presence_of :post
  validates_presence_of :content
  
  after_create :notify_relevant_users, :index_post
  
  def notify_relevant_users
    ShareMailer.new_comment_email(other_thread_participants.map(&:email), self).deliver
  end
  handle_asynchronously :notify_relevant_users
  
  def index_post
    post.reindex!
  end
  
  def word_count
    renderer = Redcarpet::Markdown.new(HTMLwithPygmentsAndTargetBlankAutolinks, autolink: true, fenced_code_blocks: true)
    Sanitize.clean(renderer.render(content), elements: ['p', 'span', 'a', 'b', 'em', 'strong', 'i'], remove_contents: true).word_count
  end
  
  def url
    "http:#{Domain.url}#{path}"
  end
  
  def url_with_email_token(user)
    "http:#{Domain.url}#{path_with_email_token(user.share_token.first(10))}"
  end
  
  def path
    "/reader/posts/#{post.id}#comment-#{id}"
  end
  
  def path_with_email_token(token)
    "/reader/posts/#{post.id}?email_token=#{token}#comment-#{id}"
  end
  
  def to_partial
    view = ActionView::Base.new(ActionController::Base.view_paths, {})
    view.extend ApplicationHelper
    view.extend ReaderHelper
    view.render(partial: "reader/comment", locals: {comment: self, current_user: nil})
  end
    
  private
  
  def other_thread_participants
    post.thread_participants - [user]
  end
end