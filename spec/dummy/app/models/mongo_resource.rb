class MongoResource
  include Mongoid::Document

  embedded_in :mongo_group, inverse_of: nil

  field :name, type: String
end
