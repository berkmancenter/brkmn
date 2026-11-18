# frozen_string_literal: true

class CreateApiTokens < ActiveRecord::Migration[7.2]
  def change
    create_table :api_tokens do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false, limit: 100
      t.text :note
      t.integer :access_level, null: false, default: 0
      # Only a SHA-256 digest of the secret is stored; the plaintext is shown once.
      t.string :token_digest
      t.string :token_prefix, limit: 20
      t.integer :lifetime_days
      t.datetime :expires_at
      t.datetime :last_used_at
      # Single-use link that lets an external user collect their token.
      t.string :claim_digest
      t.datetime :claim_expires_at
      t.datetime :claimed_at
      t.references :created_by, foreign_key: {to_table: :users}
      t.datetime :revoked_at
      t.references :revoked_by, foreign_key: {to_table: :users}
      t.timestamps
    end

    add_index :api_tokens, :token_digest, unique: true
    add_index :api_tokens, :claim_digest, unique: true
    add_index :api_tokens, :revoked_at
    add_index :api_tokens, :expires_at
    add_check_constraint :api_tokens, "access_level IN (0, 1)", name: "api_tokens_access_level"
    add_check_constraint :api_tokens,
      "lifetime_days IS NULL OR lifetime_days > 0",
      name: "api_tokens_lifetime_days_positive"
  end
end
