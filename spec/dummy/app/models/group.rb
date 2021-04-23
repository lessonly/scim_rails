# frozen_string_literal: true

class Group < ApplicationRecord
  belongs_to :company
  has_many :group_users
  has_many :users, through: :group_users

  validates \
    :name,
    presence: true,
    uniqueness: {
      case_insensitive: true,
      scope: :company
    }
end
