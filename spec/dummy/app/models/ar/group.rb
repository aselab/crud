class Ar::Group < ApplicationRecord
  acts_as_permissible manage: 0b11, read: 0b01, default: 0b01

  validates :name, presence: true
end
