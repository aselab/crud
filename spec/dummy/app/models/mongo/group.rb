class Mongo::Group
  include Mongoid::Document
  acts_as_permissible manage: 0b11, read: 0b01, default: 0b01

  field :name, type: String
  validates :name, presence: true
end
