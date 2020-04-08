class Group < ActiveRecord::Base
  belongs_to :company

  has_many :users, through: :groups_users
  has_many :groups_users
end
