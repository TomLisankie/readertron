class AddBuzzComments < ActiveRecord::Migration
  BUZZ_PROFILES = {
    "116998564030801356174" => User.find_by_email("mikesilber@gmail.com"),
    "104125957206767893406" => User.find_by_email("justinsbecker@gmail.com"),
    "112955464086661738764" => User.find_by_email("avinashvora@gmail.com"),
    "110777982215745198113" => User.find_by_email("jcobb@jd12.law.harvard.edu"),
    "107639420955391377050" => User.find_by_email("jsomers@gmail.com"),
    "116792178809368753926" => User.find_by_email("robert.trangucci@gmail.com"),
    "109696946535066138939" => User.find_by_email("shafman4@gmail.com"),
    "109334360364414775189" => User.find_by_email("pingoaf@gmail.com"),
    "117433069286907320901" => User.find_by_email("nsrivast@gmail.com"),
    "105826022922489046308" => User.find_by_email("jyl702@gmail.com"),
    "108340642828450764834" => User.find_by_email("sharon.traiberman@gmail.com")
  }
  
  def up
    transaction do
      Comment.record_timestamps = false
      Post.record_timestamps = false
      Comment.skip_callback(:create, :after, :notify_relevant_users)
      Post.skip_callback(:create, :after, :cache)
      Post.skip_callback(:create, :after, :generate_unreads)
      BUZZ_PROFILES.each do |buzz_id, user|
        puts "-" * 80
        puts "Adding Buzz comments on #{user.name}'s posts:"
        puts "-" * 80
        Dir.glob(File.join(Rails.root, "tmp", "google_reader", "buzz", buzz_id, "*")).each do |path|
          begin
            html = Nokogiri::HTML(File.open(path).read)
            url = html.css(".original-content a")[-2].try(:[], "href") || html.css(".entry-content a")[-2].try(:[], "href")
            post = Post.reader.find_by_url(url)
            if post.nil?
              post = user.feed.posts.create!({
                title: HTMLEntities.new.decode(html.css(".entry-content b").inner_html).presence || "(title unknown)",
                shared: true,
                note: html.css(".original-content").inner_html.split("<a href=\"#{url}").first.presence.try(:chomp, "<br><br>"),
                url: url,
                content: '[Read this post at the source by clicking the title above]',
                published: Time.parse(html.css(".published").first["title"]),
                created_at: Time.parse(html.css(".updated").first["title"]),
                updated_at: Time.parse(html.css(".updated").first["title"]),
                reader_id: html.css(".id").text
              })
              post.update_attributes!({original_post_id: post.id})
              puts "Created a post called #{HTMLEntities.new.decode(html.css(".entry-content b").inner_html)}"
            end
            html.css(".comment").each do |comment_html|
              next if BUZZ_PROFILES[comment_html.css(".uid").text].nil?
              puts "Adding a comment by #{BUZZ_PROFILES[comment_html.css(".uid").text].name}"
              post.comments.create!({
                content: comment_html.css(".entry-content").first.inner_html,
                user: BUZZ_PROFILES[comment_html.css(".uid").text],
                created_at: Time.parse(comment_html.css(".published").first["title"]),
                updated_at: Time.parse(comment_html.css(".updated").first["title"])
              })
            end
          rescue Exception => e
            puts e
            binding.pry
            next
          end
        end
      end
      Post.record_timestamps = true
      Comment.record_timestamps = true
      Post.set_callback(:create, :after, :cache)
      Post.set_callback(:create, :after, :generate_unreads)
      Comment.set_callback(:create, :after, :notify_relevant_users)
    end
  end

  def down
  end
end
