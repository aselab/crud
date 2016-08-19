class Group < ActiveRecord::Base
  acts_as_permissible manage: 0b11, read: 0b01, default: 0b01
  has_many :users

  validates :name, :presence => true
end
