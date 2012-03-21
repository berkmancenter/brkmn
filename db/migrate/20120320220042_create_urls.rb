class CreateUrls < ActiveRecord::Migration
  def change
    create_table :urls do |t|
      t.string :from, :limit => 255, :null => false
      t.string :to, :limit => 10.kilobytes, :null => false
      t.integer :user_id 
      t.boolean :public, :default => true

      t.timestamps
    end
    [:from, :to, :user_id, :public].each do|col|
      add_index :urls, col
    end
  end
end
