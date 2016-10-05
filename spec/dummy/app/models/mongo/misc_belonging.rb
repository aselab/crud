class Mongo::MiscBelonging
  include Mongoid::Document
  belongs_to :misc
  field :name, type: String
  validates :name, presence: true
end
