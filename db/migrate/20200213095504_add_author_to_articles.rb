class AddAuthorToArticles < ActiveRecord::Migration[5.2]
  def change
	change_table :articles do |t|
		t.column :author, :string
	end
  end
end
