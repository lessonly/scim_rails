# frozen_string_literal: true

class GroupUser < ApplicationRecord
  belongs_to :group
  belongs_to :user
end
