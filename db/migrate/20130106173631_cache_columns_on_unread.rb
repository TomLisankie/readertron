class CacheColumnsOnUnread < ActiveRecord::Migration
  def up
    add_column :unreads, :shared, :boolean, :default => false
    add_column :unreads, :feed_id, :integer
    add_index :unreads, :shared
    add_index :unreads, :feed_id

    Unread.find_each do |unread|
      unread.update_attributes(shared: unread.post.try(:shared?), feed_id: unread.post.try(:feed_id))
    end
  end

  def down
    remove_column :unreads, :shared
    remove_column :unreads, :feed_id
  end
end
