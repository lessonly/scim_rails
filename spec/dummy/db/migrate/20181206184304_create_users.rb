class CreateUsers < ActiveRecord::Migration[5.0]
  def change
    create_table :users do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false

      t.integer :company_id

      t.timestamp :archived_at

      t.timestamps null: false
    end
  end
end
