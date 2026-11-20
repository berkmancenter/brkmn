# frozen_string_literal: true

class AddUniqueIndexToUrlsShortened < ActiveRecord::Migration[8.1]
  def up
    rename_duplicate_shortcodes
    remove_index :urls, :shortened, name: "index_urls_on_shortened"
    add_index :urls, :shortened, unique: true
  end

  def down
    remove_index :urls, :shortened, name: "index_urls_on_shortened"
    add_index :urls, :shortened
  end

  private

  # Without the index two links could get the same code. The oldest one keeps
  # the code, the others get "<code>-<id>" so no link is lost.
  def rename_duplicate_shortcodes
    duplicates = select_rows(<<~SQL.squish)
      SELECT id, shortened FROM urls
      WHERE shortened IN (SELECT shortened FROM urls GROUP BY shortened HAVING COUNT(*) > 1)
        AND id NOT IN (SELECT MIN(id) FROM urls WHERE shortened IS NOT NULL GROUP BY shortened)
      ORDER BY id
    SQL

    duplicates.each do |id, shortened|
      new_code = "#{shortened}-#{id}"
      say "Duplicate shortcode #{shortened.inspect} (url #{id}) renamed to #{new_code.inspect}"
      execute("UPDATE urls SET shortened = #{quote(new_code)} WHERE id = #{Integer(id)}")
    end
  end
end
