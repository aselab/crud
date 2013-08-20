class Person < ActiveRecord::Base
  attr_accessible :name, :position

  validates :name, :presence => true

  def label
    name
  end
end
