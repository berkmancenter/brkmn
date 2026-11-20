# frozen_string_literal: true

class AddApiOnlyToUsers < ActiveRecord::Migration[7.2]
  def change
    add_column :users, :api_only, :boolean, default: false, null: false
  end
end
