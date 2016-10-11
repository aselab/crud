class Mongo::MiscBelonging
  include Mongoid::Document
  belongs_to :misc, class_name: "Mongo::Misc"
  field :name, type: String
  validates :name, presence: true
end
