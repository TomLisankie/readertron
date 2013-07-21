class ShareMailer < ActionMailer::Base
  add_template_helper(ApplicationHelper)
  default from: "Readertron <notifications@readertron.com>"
  
  include SendGrid
  sendgrid_category :use_subject_lines
  
  def new_comment_email(recipient, comment, options = {})
    @comment = comment
    @post = @comment.post
    
    subject = if options[:mentioned]
      %(#{comment.user.name} mentioned you: "#{options[:mentioned][:excerpt]}")
    else
      %(Readertron: New comment by #{comment.user.name} on "#{comment.post.title}")
    end
    
    sendgrid_category subject
    mail(to: recipient.email, subject: subject, reply_to: "comment-replies-#{comment.post.id}@readertron.mailgun.org")
  end

  def post_email(post_id, sender_id, message, recipient)
    @post = Post.find(post_id)
    @message = message
    @sender = User.find(sender_id)

    subject = %(Readertron: #{@sender.name} has shared a post with you: "#{@post.title}")
    sendgrid_category subject
    mail(to: recipient, subject: subject, reply_to: @sender.email)
  end
  
  def bookmarklet_failure_report(exception, parameters)
    @exception = exception
    @parameters = parameters
    mail(to: "jsomers@gmail.com", subject: "Bookmarklet trouble")
  end
  
  def share_email(recipients, share)
    @share = share
    @sharer = @share.sharer
    
    subject = %(Readertron: #{@sharer.name} shared "#{@share.title}" with you)
    sendgrid_category subject
    sendgrid_recipients recipients
    mail(to: "notifications@readertron.com", subject: subject, reply_to: "comment-replies-#{@share.id}@readertron.mailgun.org")
  end
  
  def weekly_digest(recipient_id)
    @period = 1.week
    @recipient = User.find(recipient_id)
    @threads = @recipient.missed_threads_in_period(@period)
    
    subject = "Readertron Weekly Digest, Week of #{Date.today.to_s(:long_ordinal)}"
    sendgrid_category subject
    mail(to: @recipient.email, subject: subject, reply_to: "jsomers@gmail.com")
  end
end
