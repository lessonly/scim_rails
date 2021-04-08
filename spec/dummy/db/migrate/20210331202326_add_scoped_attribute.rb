class AddScopedAttribute < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :scoped_attribute, :boolean, default: true
  end
end
