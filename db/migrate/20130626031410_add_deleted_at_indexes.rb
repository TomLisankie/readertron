class AddDeletedAtIndexes < ActiveRecord::Migration
  def up
    add_index :posts, :deleted_at
    add_index :comments, :deleted_at
  end

  def down
  end
end