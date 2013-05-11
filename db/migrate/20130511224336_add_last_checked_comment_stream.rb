class AddLastCheckedCommentStream < ActiveRecord::Migration
  def up
    add_column :users, :last_checked_comment_stream_at, :datetime, default: 1.week.ago
  end

  def down
    remove_column :users, :last_checked_comment_stream_at
  end
end
