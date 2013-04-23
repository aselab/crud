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
      self.define_singleton_method(:flags) {|key = nil|
        begin
          key ? permissions.fetch(key.to_sym) : permissions
        rescue
          raise ArgumentError.new("permission #{key} is not defined (must be #{permissions.keys.join(", ")})")
        end
      }

      self.class_eval do
        has_many :permissions, :as => :permissible, :dependent => :destroy,
          :after_add => :assign_default_flags

        has_many :users, :through => :permissions

        accepts_nested_attributes_for :permissions, :allow_destroy => true
        attr_accessible :permissions_attributes, :as => :admin

        scope :permissible, lambda {|user_ids, permission|
          includes(:permissions).
            where("permissions.user_id" => user_ids).
            where(permission_condition(permission))
        }
      end
    end

    def permission_condition(permission)
      ["permissions.flags & :f = :f", :f => flags(permission)]
    end
  end

  module InstanceMethods
    def add_permission(user, permission)
      p = self.permissions.build
      p.user = user
      p.flags = permission.is_a?(Symbol) ? self.class.flags(permission) : permission
      p.save!
      p
    end

    def authorized_users(permission)
      self.users.includes(:permissions).
        where(self.class.permission_condition(permission))
    end

    private
    def assign_default_flags(record)
      record.flags ||= self.class.flags[:default]
    end
  end

  class Railtie < ::Rails::Railtie #:nodoc:
    initializer "acts_as_permissible" do
      ActiveRecord::Base.send(:include, Acts::Permissible)
    end
  end
end
end
