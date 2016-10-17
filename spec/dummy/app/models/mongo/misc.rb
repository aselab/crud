class Mongo::Misc
  include Mongoid::Document
  extend Enumerize

  has_many :misc_belongings, class_name: "Mongo::MiscBelonging"
  embeds_many :misc_embeds, class_name: "Mongo::MiscEmbed"
  has_and_belongs_to_many :misc_habtms, class_name: "Mongo::MiscHabtm"

  field :boolean, type: Mongoid::Boolean
  field :string, type: String
  field :integer, type: Integer
  field :float, type: Float
  field :datetime, type: DateTime
  field :date, type: Date
  field :time, type: Time
  field :array, type: Array
  field :enumerized, type: String

  enumerize :enumerized, in: [:A, :B, :C]
end
