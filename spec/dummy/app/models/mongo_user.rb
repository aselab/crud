class MongoUser
  include Mongoid::Document

  belongs_to :mongo_group

  field :name, type: String
  field :birth_date, type: Date
end
