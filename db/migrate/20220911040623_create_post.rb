class CreatePost < ActiveRecord::Migration[7.0]
  def change
    create_table :posts, id: :uuid do |t|
      t.text :content, null: false
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end
  end
end
