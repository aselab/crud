class Mongo::MiscEmbed
  include Mongoid::Document
  embedded_in :misc
  field :name, type: String
  validates :name, presence: true
end
