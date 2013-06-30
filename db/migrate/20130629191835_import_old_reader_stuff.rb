class ImportOldReaderStuff < ActiveRecord::Migration
  READER_SHARED_FEEDS = {
    "04999129223109377191" => User.find_by_email("jsomers@gmail.com"),
    "00782089014673520202" => User.find_by_email("shafman4@gmail.com"),
    "18315144321056611041" => User.find_by_email("pingoaf@gmail.com"),
    "18307325206315513246" => User.find_by_email("nsrivast@gmail.com"),
    "16681490915960711550" => User.find_by_email("jcobb@jd12.law.harvard.edu"),
    "15463632940681726647" => User.find_by_email("robert.trangucci@gmail.com"),
    "13084319676098510123" => User.find_by_email("drew.blacker@gmail.com"),
    "10191768057804232612" => User.find_by_email("avinashvora@gmail.com"),
    "04708450034178694932" => User.find_by_email("justinsbecker@gmail.com"),
    "01605071625535819377" => User.find_by_email("mikesilber@gmail.com"),
    "00099982683447943563" => User.find_by_email("tvchurch@gmail.com")
  }
  
  def up
    transaction do
      add_column :posts, :reader_id, :string
      add_index :posts, :reader_id
      Post.record_timestamps = false
      Comment.record_timestamps = false
      Post.skip_callback(:create, :after, :cache)
      Post.skip_callback(:create, :after, :generate_unreads)
      Comment.skip_callback(:create, :after, :notify_relevant_users)
      READER_SHARED_FEEDS.each do |reader_id, user|
        puts "-" * 80
        puts "Adding items for #{user.name}:"
        puts "-" * 80
        Dir.glob(File.join(Rails.root, "tmp", "google_reader", "#{reader_id}*")).each do |path|
          JSON.parse(File.open(path).read)["items"].each do |item|
            next if item['title'].blank?
            puts "Creating #{item['title']}..."
            begin
              post = user.feed.posts.create!({
                title: HTMLEntities.new.decode(item["title"]),
                shared: true,
                note: item["annotations"].first.try(:[], "content"),
                url: item["canonical"] ? item["canonical"][0]["href"] : item["alternate"][0]["href"],
                content: item["content"].try(:[], "content").presence || '[Read this post at the source by clicking the title above]',
                published: Time.at(item["published"]),
                created_at: Time.at(item["published"]),
                updated_at: Time.at(item["published"]),
                reader_id: item["id"]
              })
              post.update_attributes!({original_post_id: post.id})
              
              item["comments"].each do |comment|                
                next unless READER_SHARED_FEEDS[comment["userId"]]
                post.comments.create!({
                  content: comment["htmlContent"],
                  user: READER_SHARED_FEEDS[comment["userId"]],
                  created_at: Time.at(comment["createdTime"]),
                  updated_at: Time.at(comment["modifiedTime"])
                })
              end
            rescue Exception => e
              puts e
              binding.pry
              next
            end
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
    remove_column :posts, :reader_id
  end
end
