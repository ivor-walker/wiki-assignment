class AddArticleTable < ActiveRecord::Migration[5.2]
  def change
	create_table :articles do |t|
		t.string :name
		t.string :body
		t.datetime :date
	end
  end
end
