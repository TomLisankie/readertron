class FixUniqueIndexOnPosts < ActiveRecord::Migration
  def up
    remove_index :posts, name: "url"
    remove_index :posts, name: "index_posts_on_url_and_shared"
    
    add_index :posts, [:url, :shared, :deleted_at], unique: true
  end

  def down
  end
end
