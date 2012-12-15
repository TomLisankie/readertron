class ShareMailer < ActionMailer::Base
  add_template_helper(ApplicationHelper)
  default from: "Readertron <notifications@readertron.com>"
  
  def new_comment_email(user, comment)
    @user = user
    @comment = comment
    mail(to: user.email, subject: "#{comment.user.name} commented on \"#{comment.post.title}\"", reply_to: "comment-replies-#{comment.post.id}@readertron.mailgun.org")
  end

  def post_email(post, sender, message, recipient)
    @post = post
    @message = message
    @sender = sender
    mail(to: recipient, subject: "#{sender.name} has shared a Readertron post with you: \"#{post.title}\"", reply_to: sender.email)
  end
end
