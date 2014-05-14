class MongoUser
  include Mongoid::Document
  field :name, type: String
  field :birth_date, type: Date
end
