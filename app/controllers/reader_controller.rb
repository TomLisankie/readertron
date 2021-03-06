class ReaderController < ApplicationController
  before_filter :authenticate_user!, except: [:create_post, :bookmarklet, :email_comment, :email_share, :posts]
  protect_from_forgery :except => [:create_post, :bookmarklet, :email_comment, :email_share]
  require 'iconv'
  
  def index
    redirect_to "/reader/posts/#{params[:post_id]}" if params[:post_id].present?
  end
  
  def subscriptions
    @shared, @unshared = current_user.subscriptions(:include => :feeds).partition {|s| s.feed.shared?}
        
    @unread_counts, @shared_unread_count = current_user.unread_counts

    @title = "(#{@unread_count = @unread_counts.values.sum})"
    @unread_count = @unread_counts.values.sum
    @comment_unseen_count = current_user.comment_unseen_count
    @shared_unread_count = current_user.shared_unread_count_total
    @regular_unread_count = @unread_count - @shared_unread_count
    render layout: false
  end
  
  def index_entries
    @entries = Post.cached(current_user.unreads.unshared.order("published ASC").limit(10).map(&:post_id)) rescue []
    Rails.cache.write("#{current_user.id}__chron", current_user.unreads.unshared.map(&:post_id))
    render layout: false
  end
  
  def posts
    @entry = Post.find(params[:id])
    @title = "- #{@entry.title}"
    if (tok = params[:email_token])
      sign_in User.where(["share_token like ?", "#{tok}%"]).first
    else
      authenticate_user!
    end
    render "single"
  end
  
  def entries
    if params[:items_filter] == 'unread'
      @entries = Post.unread_for_options(current_user, params[:date_sort], @page = params[:page].to_i, params[:feed_id]) 
    else
      @entries = Post.for_options(current_user, params[:date_sort], @page = params[:page].to_i, params[:feed_id])
    end

    if feed = Feed.find_by_id(@feed_id = params[:feed_id])
      @feed_name = (feed.title || feed.feed_url) 
    end

    render layout: false
  end
  
  def mark_as_read
    post = Post.find(params[:post_id])
    Unread.find_by_user_id_and_post_id(current_user.id, post.id).try(:destroy)
    render json: {feed_id: post.feed.id}
  end
  
  def mark_as_unread
    post = Post.find(params[:post_id])
    unless (u = Unread.find_by_user_id_and_post_id(current_user.id, post.id))
      u = Unread.create(post_id: post.id, user_id: current_user.id, feed_id: post.feed_id, shared: post.shared?)
    end
    render json: {feed_id: post.feed.id}
  end
  
  def post_share
    post = Post.find(params[:post_id])
    unless (share = current_user.feed.posts.find_by_original_post_id(params[:post_id]))
      share = current_user.feed.posts.create!(post.attributes.merge(shared: true, original_post_id: post.id, created_at: Time.now))
      Post.delay.send_share_emails(share.id)
    end
    render text: "OK"
  end
  
  def post_unshare
    post = current_user.feed.posts.find_by_original_post_id(params[:post_id])
    post.try(:destroy)
    render text: "OK"
  end
  
  def share_with_note
   post = Post.find(params[:post_id])
    unless (share = current_user.feed.posts.find_by_original_post_id(params[:post_id]))
      share = current_user.feed.posts.create!(post.attributes.merge(shared: true, original_post_id: post.id, note: params[:note_content], created_at: Time.now))
      Post.delay.send_share_emails(share.id)
    end
    render text: "OK"
  end
  
  def create_comment
    post = Post.find(params[:post_id])
    comment = post.comments.create(content: params[:comment_content], user: current_user)
    render partial: "reader/comment", :locals => {comment: comment}
  end
  
  def delete_comment
    comment = Comment.find_by_id(params[:comment_id])
    if comment && comment.user == current_user
      comment.destroy
    end
    render text: "OK"
  end
  
  def edit_comment
    comment = Comment.find_by_id(params[:comment_id])
    if comment && comment.user == current_user
      comment.update_attributes({content: params[:comment_content]})
    end
    render partial: "reader/comment", :locals => {comment: comment}
  end
  
  def create_post
    @post = User.find_by_share_token(params[:token]).feed.posts.create(
      content: utf8clean(params[:content].presence || "[Click through to the original story.]"),
      url: utf8clean(params[:url]),
      note: utf8clean(params[:note]),
      title: utf8clean(params[:title]),
      published: Time.now,
      shared: true
    )
    @post.update_attributes!({original_post_id: @post.id})
    Post.delay.send_share_emails(@post.id)
    @origin = params[:origin]
    render layout: false
  rescue Exception => e
    sharer = User.find_by_share_token(params[:token]).try(:name)
    ShareMailer.bookmarklet_failure_report(e, params.merge(sharer: sharer)).deliver
  end
  
  def edit_note
    entry = Post.find(params[:post_id])
    entry.update_attributes!({note: params[:content]})
    render partial: "reader/entry_note", :locals => {entry: entry}
  end
  
  def delete_note
    entry = Post.find(params[:post_id])
    entry.update_attributes!({note: nil})
    render text: "OK"
  end
  
  def quickpost
    p = current_user.feed.posts.create(
      content: params[:content],
      title: params[:title],
      published: Time.now,
      url: "#quickpost-#{current_user.name.snake}-#{Time.now.to_i}",
      shared: true,
      author: "#{current_user.name} (Quickpost)"
    )
    p.update_attributes!({original_post_id: p.id})
    
    Post.delay.send_share_emails(p.id)
    render text: "OK"
  end
  
  def edit_quickpost
    entry = Post.find(params[:post_id])
    entry.update_attributes!({content: params[:content]})
    render text: "OK"
  end
  
  def delete_share
    entry = Post.find(params[:post_id])
    entry.destroy
    render text: "OK"
  end

  def stream
	  @comments = Comment.where(["user_id != ?", current_user.id]).paginate(page: params[:page], per_page: 10).order("created_at DESC")
    @title = "- Comments"
    @title += " (#{current_user.comment_unseen_count})" if current_user.comment_unseen_count > 0
  end
  
  def search
    @title = %{- Search results for "#{params[:query]}"}
    @page = (params[:page].to_i || 1)
    @results = Post.search(current_user, params)
  end
  
  def bookmarklet
    @token = params[:token]
    respond_to do |format|
      format.js
    end
  end
  
  def email_comment
    user = User.find_by_email(params["sender"])
    post = Post.find(params["recipient"][/comment-replies-(.*?)@/, 1])
    content = params["stripped-text"]
    post.comments.create(user: user, content: content)
    render :text => "OK", :status => 200
  rescue Exception => e
    Report.create(report_type: "failed_mailgun", content: {email: params, exception: e})
  end
  
  def email_share
    note = utf8clean(params["stripped-text"]).split(/https?:\/\/[\S]+/).first.try(:strip)
    doc = Nokogiri::HTML(utf8clean(params['body-html'] || params['stripped-html']))
    body = if (article = doc.at_css('#article'))
      article.to_html
    else
      params['stripped-text'][/(https?:\/\/[\S]+)/, 1]
    end
    url = utf8clean(doc.at_css('a').try(:[], 'href') || params['stripped-text'][/(https?:\/\/[\S]+)/, 1] || "")
    user = User.find_by_email(params["sender"])
    
    if body.blank? && url.blank?
      url = "#quickpost-#{user.name.snake}-#{Time.now.to_i}"
      body = params['stripped-text']
      note = nil
    else
      body = absolutize_relative_paths(url, body)
    end
    
    post = user.feed.posts.create!(
      content: body,
      url: url,
      title: utf8clean(params[:subject]),
      note: note,
      published: Time.now,
      shared: true
    )
    post.update_attributes!({original_post_id: post.id})
    Post.delay.send_share_emails(post.id)
    
    render :text => "OK", :status => 200
  rescue Exception => e
    Report.create(report_type: "failed_mailgun", content: {email: params, exception: e})
  end

  def email_post
    post = Post.find(params[:post_id])
    message = params[:message]
    recipient = params[:recipient]
    ShareMailer.delay.post_email(post.id, current_user.id, message, recipient)
    render text: "OK"
  end
  
  def markdownify
    @content = params[:content]
    render layout: false
  end

  private

  def utf8clean(str)
    CGI.unescape(str.force_encoding(Encoding::UTF_8))
  end
  
  def absolutize_relative_paths(url, content)
    new_content = "" + content
    doc = Nokogiri::HTML(content)
    doc.css("a").each do |link|
      link_url = link['href']
      begin absolute_link_url = URI.join(url, link_url).to_s rescue next end
      new_content = new_content.gsub(link_url, absolute_link_url)
    end
    new_content
  end
end