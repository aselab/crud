module Acts
module Permissible
  def self.included(base)
    base.extend(ClassMethods)
    base.send(:include, InstanceMethods)
  end

  module ClassMethods
    # アクセス権をビットで定義する
    # {:manage => 0b111, :write => 0b011, :read => 0b001, :default => 0b001}
    def acts_as_permissible(permissions)
      self.define_singleton_method(:defined_permissions) { permissions }

      self.class_eval do
        has_many :permissions, :as => :permissible, :dependent => :destroy,
          :before_add => :assign_default_flags

        has_many :users, :through => :permissions

        accepts_nested_attributes_for :permissions, :allow_destroy => true
        attr_accessible :permissions_attributes, :as => :admin

        scope :permissible, lambda {|user_ids, action|
          flag = permissions[action.to_sym]
          raise ArgumentError.new("action #{action} is not defined (must be #{permissions.keys.join(", ")})") if flag.nil?

          includes(:permissions).where([
            "permissions.user_id IN (:ids) AND permissions.flags & :flag = :flag",
            :ids => user_ids, :flag => flag
          ])
        }
      end
    end
  end

  module InstanceMethods
    private
    def assign_default_flags(record)
      record.flags ||= self.class.defined_permissions[:default]
    end
  end

  class Railtie < ::Rails::Railtie #:nodoc:
    initializer "acts_as_permissible" do
      ActiveRecord::Base.send(:include, Acts::Permissible)
    end
  end
end
end
