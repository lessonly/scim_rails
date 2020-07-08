class CreateUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :users do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false

      t.string :email, null: false
      t.string :alternate_email

      t.boolean :random_attribute, default: false
      t.string :test_attribute

      t.integer :company_id

      t.timestamp :archived_at

      t.timestamps null: false
    end
  end
end
