class MongoResource
  include Mongoid::Document

  embedded_in :mongo_group

  field :name, type: String
end
