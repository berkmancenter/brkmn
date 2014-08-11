class DefaultClicksTo0 < ActiveRecord::Migration
  def up
    change_column_default :urls, :clicks, 0
  end

  def down
    change_column_default :urls, :clicks, :integer, nil
  end
end
