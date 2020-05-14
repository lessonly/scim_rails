class Group < ApplicationRecord
  belongs_to :company

  has_many :users, through: :groups_users
  has_many :groups_users

  validates \
    :display_name,
    :email,
    presence: true

  validates \
    :display_name,
    uniqueness: {
      case_insensitive: false
    }

  def active?
    archived_at.blank?
  end

  def archived?
    archived_at.present?
  end

  def archive!
    write_attribute(:archived_at, Time.current)
    save!
  end

  def unarchived?
    archived_at.blank?
  end

  def unarchive!
    write_attribute(:archived_at, nil)
    save!
  end
end
