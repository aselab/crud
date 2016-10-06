class Mongo::Misc
  include Mongoid::Document
  has_many :misc_belongings
  embeds_many :misc_embeds

  field :boolean, type: Mongoid::Boolean
  field :string, type: String
  field :integer, type: Integer
  field :float, type: Float
  field :datetime, type: Time
  field :date, type: Date
  field :time, type: Time
  field :array, type: Array
end
