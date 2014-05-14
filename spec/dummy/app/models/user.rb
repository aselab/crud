class User < ActiveRecord::Base
  has_many :permissions, dependent: :destroy

  validates :name, :presence => true
end
