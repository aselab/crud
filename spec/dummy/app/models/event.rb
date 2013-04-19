class Event < ActiveRecord::Base
  acts_as_permissible :manage => 0b11, :read => 0b01, :default => 0b01

  attr_accessible :name
end
