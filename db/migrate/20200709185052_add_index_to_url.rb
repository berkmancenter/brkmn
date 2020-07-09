class AddIndexToUrl < ActiveRecord::Migration[6.0]
  def change
    add_index :urls, :clicks
  end
end
