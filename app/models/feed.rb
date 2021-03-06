class Feed < ActiveRecord::Base  
  has_many :subscriptions, :dependent => :destroy
  has_many :users, :through => :subscriptions
  has_many :posts, :dependent => :destroy

  after_save :get_favicon
  before_destroy :remove_favicon
  
  validates_presence_of :feed_url
  validates_uniqueness_of :feed_url, unless: ->(feed) { feed.shared? }

  module OPML
    class Outline
      include HappyMapper
        tag 'outline'
        attribute :title, String
        attribute :text, String
        attribute :type, String
        attribute :xmlUrl, String
        attribute :htmlUrl, String
        has_many :outlines, Outline
    end
  end
  
  def self.clean_url(url)
    if url.match(/^http/).present?
      url = url.gsub("www.", "") if url.match(/http:\/\/www\./).present?
    else
      url = url.gsub("www.", "") if url.match(/^www\./).present?
      url = "http://#{url}"
    end
    url
  end
  
  def self.shared
    where(shared: true)
  end
  
  def self.unshared
    where(shared: false)
  end
  
  def self.all_for_opml(opml)
    OPML::Outline.parse(opml).map(&:xmlUrl).map {|feed_url| create_if_needed(clean_url(feed_url))}
  end
  
  def self.create_if_needed(feed_url)
    if (f = find_by_feed_url(feed_url))
      return f
    else
      fz = Feedzirra::Feed.fetch_and_parse(feed_url)
      if !fz.is_a?(Fixnum) && fz.present?
        if (f = find_by_title(fz.title))
          return f
        end
        if (f = find_by_url(fz.url))
          return f
        end
      end
    end
    return create(feed_url: feed_url)
  end
  
  def self.fuzzy_find(field, string)
    where("#{field} like '%#{string}%'")
  end

  def self.refresh
    # If a Feed.refresh is already running, kill it!
    `ps aux | grep ruby`.split("\n").each do |line|
      if line.include? "Feed.refresh"
        process = line.split(/\s+/)[1]
        `kill -9 #{process}` unless process == $$.to_s
      end
    end

    t = Time.now
    posts_count = Post.count(1)
    
    Feed.find_each(&:refresh)

    Report.create(report_type: "Feed.refresh", content: {
      time: Time.now - t,
      posts: Post.count(1) - posts_count
    })
  end
  
  def refresh(feedzirra=nil)
    t = Time.now
    if feedzirra.nil?
       Feedzirra::Feed.fetch_and_parse(feed_url, max_redirects: 5, timeout: 10,
        on_success: lambda {|feed_url, fz| feedzirra = fz},
        on_failure: lambda do |feed_url, response_code, response_header, response_body|
          begin
            feedzirra = Feedzirra::Feed.parse(Feedzirra::Feed.fetch_raw(feed_url))
          rescue Exception => e
            puts "Fallback failed: #{e}"
          end
        end
      )
    end
    return "Fetch failed" if (feedzirra.is_a?(Fixnum) || feedzirra.nil?)

    entries = (ne = feedzirra.new_entries).empty? ? feedzirra.entries : ne
    cutoff = (latest_post ? latest_post.published : nil)
    
    entries.each_with_index do |entry, i|
      break if entry.published && cutoff && (entry.published < cutoff)
      this_posts_date = (entry.published || (begin Date.parse(entry.summary) rescue i.days.ago end))
      threshold_date = Post.post_staleness_threshold
      next if this_posts_date < threshold_date
      posts.create({
        title: entry.title, 
        author: entry.author,
        url: entry.url,
        content: (entry.content || entry.summary), 
        published: this_posts_date
      })
    end
    
    rehydrate(feedzirra, cutoff)
    puts "-" * 80
    puts "Time: #{Time.now - t}"
    puts "-" * 80
  rescue Exception => e
    puts "#" * 80
    puts "EXCEPTION: #{e}"
    puts "#" * 80
  end
  
  def rehydrate(feedzirra, cutoff)
    update_attributes(title: feedzirra.title, url: feedzirra.url, last_modified: cutoff)
  end
  
  def latest_post
    posts.order("published ASC").last
  end
  
  def get_favicon(force=false)
    if url.present? && (url_changed? || force)
      begin
        `curl https://plus.google.com/_/favicon?domain=#{URI.parse(url).host} > #{Rails.root}/app/assets/images/favicons/#{id}.png`
      rescue
        `cp #{Rails.root}/app/assets/images/favicons/default.png #{Rails.root}/app/assets/images/favicons/#{id}.png`
      end
    end
  end
  
  def remove_favicon
    `rm #{Rails.root}/app/assets/images/favicons/#{id}.png`
  end
  
  def self.resolve_duplicates
    marked_titles = {}
    duplicated_feeds = unshared.select {|f| find_all_by_title(f.title).length > 1}.select {|f| f.title.present?}
    duplicated_feeds.each do |dupe|
      if marked_titles[dupe.title].nil?
        ActiveRecord::Base.transaction do
          copies = find_all_by_title(dupe.title).map(&:id)
          good = find(copies.first)
          copies[1..-1].each do |bad_id|
            bad = find(bad_id)
            bad.posts.each {|post| good.posts << post}
            bad.reload.subscriptions.each { |subscription| good.subscriptions << subscription }
            bad.reload.destroy
          end
        end
        marked_titles[dupe.title] = true
      end
    end
  end

end