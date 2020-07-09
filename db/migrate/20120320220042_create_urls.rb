class CreateUrls < ActiveRecord::Migration[3.2]
  def change
    create_table :urls do |t|
      t.string :shortened, limit: 255
      t.string :to, limit: 10.kilobytes, null: false
      t.integer :user_id
      t.boolean :auto, default: true

      t.timestamps
    end
    [:shortened, :to, :user_id, :auto].each do |col|
      add_index :urls, col
    end
  end
end
