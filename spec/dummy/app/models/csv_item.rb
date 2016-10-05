class CsvItem
  include Mongoid::Document
  field :string, type: String
  field :integer, type: Integer
  field :boolean, type: Boolean
  field :date, type: Date
  field :datetime, type: DateTime
end
