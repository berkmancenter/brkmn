# frozen_string_literal: true

class AddSharedEditingToUrls < ActiveRecord::Migration[7.2]
  def change
    add_reference :urls, :last_edited_by, foreign_key: {to_table: :users}
    add_column :urls, :last_edited_at, :datetime

    create_table :url_collaborators do |t|
      t.references :url, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :granted_by, foreign_key: {to_table: :users}

      t.timestamps
    end
    add_index :url_collaborators, [:url_id, :user_id], unique: true

    create_table :url_access_requests do |t|
      t.references :url, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.references :resolved_by, foreign_key: {to_table: :users}
      t.datetime :resolved_at

      t.timestamps
    end
    add_index :url_access_requests, [:url_id, :user_id], unique: true
    add_check_constraint :url_access_requests,
      "status IN (0, 1, 2)",
      name: "url_access_requests_status"
  end
end
