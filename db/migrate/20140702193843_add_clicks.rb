class AddClicks < ActiveRecord::Migration
  def up
    add_column :urls, :clicks, :integer
  end

  def down
    remove_column :urls, :clicks
  end
end
