class AddClicks < ActiveRecord::Migration[4.2]
  def up
    add_column :urls, :clicks, :integer
  end

  def down
    remove_column :urls, :clicks
  end
end
