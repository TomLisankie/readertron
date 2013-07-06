class RemoveDeletedAt < ActiveRecord::Migration
  def up
    remove_index :posts, name: "index_posts_on_url_and_shared_and_deleted_at"
    remove_column :posts, :deleted_at
    remove_column :comments, :deleted_at
    
    add_index :posts, :url
  end

  def down
  end
end