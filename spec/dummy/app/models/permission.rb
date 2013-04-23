class Permission < ActiveRecord::Base
  belongs_to :user, :class_name => 'Principal'
  belongs_to :permissible, :polymorphic => true

  attr_accessible :flags, :as => :admin
end
