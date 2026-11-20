# frozen_string_literal: true

# Devise :recoverable was enabled for password log in, but its columns were
# never added, so "Forgot your password?" failed.
class AddRecoverableToUsers < ActiveRecord::Migration[8.1]
  def change
    change_table :users, bulk: true do |t|
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
    end
    add_index :users, :reset_password_token, unique: true
  end
end
