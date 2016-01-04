class Misc
  include Mongoid::Document
  field :boolean, type: Mongoid::Boolean
  field :string, type: String
  field :email, type: String
  field :url, type: String
  field :phone, type: String
  field :password, type: String
  field :integer, type: Integer
  field :datetime, type: DateTime
  field :date, type: Date
  field :time, type: Time
  field :time_zone, type: String
end
