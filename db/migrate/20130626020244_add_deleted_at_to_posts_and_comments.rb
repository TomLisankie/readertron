class AddDeletedAtToPostsAndComments < ActiveRecord::Migration
  def change
    add_column :posts, :deleted_at, :datetime
    add_column :comments, :deleted_at, :datetime
  end
end
