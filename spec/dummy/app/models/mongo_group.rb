class MongoGroup
  include Mongoid::Document

  has_many :mongo_users

  field :name, type: String
end
