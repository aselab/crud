class Mongo::Permission
  include Mongoid::Document

  belongs_to :user, class_name: "Mongo::User"
  embedded_in :permissible, polymorphic: true
  field :flags, type: Array

  def flags
    read_attribute(:flags).try(:inject, :+)
  end

  def flags=(value)
    value = value.is_a?(Array) ? value : permissible.class.split_flag(value.to_i)
    write_attribute(:flags, value)
    flags
  end
end
