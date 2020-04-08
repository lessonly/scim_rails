class CreateGroups < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.string :display_name

      t.timestamps null: false
    end
  end
end
