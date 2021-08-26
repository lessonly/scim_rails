class AddDepaartmentToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :department, :string
  end
end
