class CreateGroupsUsers < ActiveRecord::Migration[5.2]
  def change
    create_table :groups_users do |t|
      t.references :user, index: true, foreign_key: true
      t.references :group, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
