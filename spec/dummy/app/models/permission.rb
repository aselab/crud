class Permission < ActiveRecord::Base
  belongs_to :principal, :class_name => 'Principal'
  belongs_to :permissible, :polymorphic => true

  attr_accessible :flags, :as => :admin
end
