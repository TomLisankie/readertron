class AddIndexesToPost < ActiveRecord::Migration
  def change
    add_index :posts, [:url, :shared], :unique => true
  end
end
