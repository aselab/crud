module Acts
module Permissible
  # アクセス権をビットで定義する
  # {:manage => 0b111, :write => 0b011, :read => 0b001, :default => 0b001}
  def acts_as_permissible(permissions)
    self.define_singleton_method(:all_flags) {permissions}

    self.class_eval do
      extend ClassMethods
      include InstanceMethods

      has_many :permissions, :as => :permissible, :dependent => :destroy,
        :after_add => :set_default_flag, :extend => AssociationExtensions

      has_many :users, :through => :permissions

      accepts_nested_attributes_for :permissions, :allow_destroy => true

      scope :permissible, lambda {|user_ids, permission|
        includes(:permissions).references(:permissions).
          where("permissions.user_id" => user_ids).
          where(permission_condition(permission))
      }
    end
  end

  module ClassMethods
    def permission_condition(permission)
      ["permissions.flags & :f = :f", :f => flags(permission)]
    end

    def permission_translate(permission)
      @permission_prefix ||= "permission.#{model_name.i18n_key}"
      p = permission.to_s
      I18n.t("#{@permission_prefix}.#{p}", :default => p.humanize)
    end

    def permission_label(flag, restrict = true)
      keys = if restrict
        @inverted_flags ||= flags.invert
        Array(@inverted_flags[flag])
      else
        flags.map {|k, v| k if v & flag == flag}.compact
      end
      keys.map {|k| permission_translate(k)}.join(",") unless keys.empty?
    end

    def permission_options
      flags.map {|k, v| [permission_translate(k), v]}
    end

    def flags(key = nil)
      unless @flags
        @flags = all_flags.dup
        @flags.delete(:default)
        @flags.freeze
      end
      key ? @flags.fetch(key.to_sym) : @flags
    rescue
      raise ArgumentError.new("permission #{key} is not defined (must be #{@flags.keys.join(", ")})")
    end

    def default_flag
      all_flags[:default]
    end
  end

  module InstanceMethods
    def authorized_users(permission)
      self.users.includes(:permissions).references(:permissions).
        where(self.class.permission_condition(permission))
    end

    private
    def set_default_flag(record)
      record.flags ||= self.class.default_flag
    end
  end

  module AssociationExtensions
    def add(user, permission = nil)
      create_or_update(user) {|p| p.flags |= flags(permission) if permission}
    end

    def mod(user, permission)
      create_or_update(user) {|p| p.flags = flags(permission)}
    end

    private
    def flags(permission)
      permission.is_a?(Symbol) ?
        proxy_association.owner.class.flags(permission) : permission
    end

    def create_or_update(user)
      p = self.where(:user_id => user).first || self.build
      p.user = user
      yield p
      p.save!
      p
    end
  end

  class Railtie < ::Rails::Railtie #:nodoc:
    initializer "acts_as_permissible" do
      ActiveSupport.on_load(:active_record) do
        ActiveRecord::Base.extend Acts::Permissible
      end
    end
  end
end
end
