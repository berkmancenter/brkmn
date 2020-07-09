class AddClicks < ActiveRecord::Migration[3.2]
  def up
    add_column :urls, :clicks, :integer
  end

  def down
    remove_column :urls, :clicks
  end
end
