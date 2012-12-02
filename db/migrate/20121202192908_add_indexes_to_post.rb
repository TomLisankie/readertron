class AddIndexesToPost < ActiveRecord::Migration
  def change
    add_index :posts, :url, :unique => true
  end
end
