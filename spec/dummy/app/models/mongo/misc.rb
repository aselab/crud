class Mongo::Misc
  include Mongoid::Document
  extend Enumerize

  has_many :misc_belongings, class_name: "Mongo::MiscBelonging"
  embeds_many :misc_embeds, class_name: "Mongo::MiscEmbed"

  field :boolean, type: Mongoid::Boolean
  field :string, type: String
  field :integer, type: Integer
  field :float, type: Float
  field :datetime, type: Time
  field :date, type: Date
  field :time, type: Time
  field :array, type: Array
  field :enumerized, type: String

  enumerize :enumerized, in: [:A, :B, :C]
end
