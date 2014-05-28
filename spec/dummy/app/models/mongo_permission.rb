class MongoPermission
  include Mongoid::Document

  belongs_to :mongo_user
  embedded_in :mongo_permissible, polymorphic: true
  field :flags, type: Array
end
