class CreateGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :groups do |t|
      t.string :display_name, null: false
      t.string :email, null: false
      t.boolean :random_attribute, default: false

      t.integer :company_id

      t.timestamp :archived_at

      t.timestamps null: false
    end
  end
end
