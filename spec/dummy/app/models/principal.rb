class Principal < ActiveRecord::Base
  has_many :permissions, :dependent => :destroy
  attr_accessible :name
end
