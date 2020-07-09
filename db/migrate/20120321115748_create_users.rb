class CreateUsers < ActiveRecord::Migration[3.2]
  def change
    create_table :users do |t|
      t.string :username, limit: 100, null: false
      t.string :email, limit: 100
      t.boolean :superadmin, default: false
      t.timestamps
    end
    [:username, :email, :superadmin].each do |col|
      add_index :users, col
    end
  end
end
