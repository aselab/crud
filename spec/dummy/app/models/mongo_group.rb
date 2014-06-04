class MongoGroup
  include Mongoid::Document

  acts_as_permissible({
    manage: 0b11, read: 0b01, default: 0b01
  }, {
    principal_name: "MongoUser",
    permission_name: "MongoPermission",
    permissible_name: :mongo_permissible
  })

  embeds_many :mongo_resources

  field :name, type: String
end
