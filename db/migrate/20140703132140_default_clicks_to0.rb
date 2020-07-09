# This and prior migrations were actually created in 3.2, but Rails does not
# acknowledge versions older than 4.2. However, the point of this is to allow
# for a compatibility layer introduced by changes between Rails 4.2 and Rails 5.
class DefaultClicksTo0 < ActiveRecord::Migration[4.2]
  def up
    change_column_default :urls, :clicks, 0
  end

  def down
    change_column_default :urls, :clicks, :integer, nil
  end
end
