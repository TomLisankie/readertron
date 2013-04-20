class ShareMailer < ActionMailer::Base
  add_template_helper(ApplicationHelper)
  default from: "Readertron <notifications@readertron.com>"
  
  def new_comment_email(user, comment)
    @user = user
    @comment = comment
    @post = @comment.post
    mail(to: user.email, subject: "Readertron: #{comment.user.name} commented on \"#{comment.post.title}\"", reply_to: "comment-replies-#{comment.post.id}@readertron.mailgun.org")
  end

  def post_email(post, sender, message, recipient)
    @post = post
    @message = message
    @sender = sender
    mail(to: recipient, subject: "Readertron: #{sender.name} has shared a post with you: \"#{post.title}\"", reply_to: sender.email)
  end
  
  def bookmarklet_failure_report(exception, parameters)
    @exception = exception
    @parameters = parameters
    mail(to: "jsomers@gmail.com", subject: "Bookmarklet trouble")
  end
  
  def share_email(recipient, share)
    @recipient = recipient
    @share = share
    @sharer = @share.sharer
    
    mail(to: @recipient.email, subject: "Readertron: #{@sharer.name} shared \"#{@share.title}\" with you", reply_to: "comment-replies-#{@share.id}@readertron.mailgun.org")
  end
end
