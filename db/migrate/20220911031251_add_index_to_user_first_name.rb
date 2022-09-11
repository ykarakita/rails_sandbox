class AddIndexToUserFirstName < ActiveRecord::Migration[7.0]
  def change
    add_index :users, :first_name
  end
end
