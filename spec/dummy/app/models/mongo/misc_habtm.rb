class Mongo::MiscHabtm
  include Mongoid::Document
  has_and_belongs_to_many :miscs, class_name: "Mongo::Misc"
  field :name, type: String
  validates :name, presence: true
end
