class DefaultClicksTo0 < ActiveRecord::Migration[3.2]
  def up
    change_column_default :urls, :clicks, 0
  end

  def down
    change_column_default :urls, :clicks, :integer, nil
  end
end
