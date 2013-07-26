class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :post
  validates_presence_of :user
  validates_presence_of :post
  validates_presence_of :content
  
  after_create :notify_relevant_users, :index_post
  
  def notify_relevant_users
    mentioned_users = []
    Mentions.get(content).each do |mention|
      recipient = User.find_by_fingerprint(mention[:fingerprint])
      next if recipient.nil?
      
      if !mentioned_users.include?(recipient)
        mentioned_users << recipient
        excerpt = content.excerpt(mention[:indices][0], mention[:indices][1], 60).strip
        ShareMailer.new_comment_email(recipient, self, mentioned: {excerpt: "..#{excerpt}.."}).deliver
      end
    end
    
    (other_thread_participants - mentioned_users).each do |recipient|
      ShareMailer.new_comment_email(recipient, self, mentioned: false).deliver
    end
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
