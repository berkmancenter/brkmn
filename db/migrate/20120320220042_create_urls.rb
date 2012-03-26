class CreateUrls < ActiveRecord::Migration
  def change
    create_table :urls do |t|
      t.string :from, :limit => 255
      t.string :to, :limit => 10.kilobytes, :null => false
      t.integer :user_id 
      t.boolean :auto, :default => true

      t.timestamps
    end
    [:from, :to, :user_id, :auto].each do|col|
      add_index :urls, col
    end
  end
end
