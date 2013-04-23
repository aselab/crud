class Principal < ActiveRecord::Base
  has_many :permissions, :dependent => :destroy, :foreign_key => "user_id"
  attr_accessible :name
end
