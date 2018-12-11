class User < ApplicationRecord
  belongs_to :company

  validates \
    :first_name,
    :last_name,
    :email,
    presence: true

  validates \
    :email,
    uniqueness: {
      case_insensitive: true
    }

  def active?
    archived_at.blank?
  end

  def archived?
    archived_at.present?
  end

  def archive!
    write_attribute(:archived_at, Time.now)
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
