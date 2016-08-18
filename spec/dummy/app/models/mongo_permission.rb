class MongoPermission
  include Mongoid::Document

  belongs_to :mongo_user, optional: true
  embedded_in :mongo_permissible, polymorphic: true
  field :flags, type: Array

  def flags
    read_attribute(:flags).try(:inject, :+)
  end

  def flags=(value)
    value = value.is_a?(Array) ? value : mongo_permissible.class.split_flag(value.to_i)
    write_attribute(:flags, value)
    flags
  end
end
