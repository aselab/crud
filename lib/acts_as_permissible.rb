module Acts
  module Permissible
    module Base
      #
      # アクセス権をビットで定義する
      #
      # permissions::
      #   {manage: 0b111, write: 0b011, read: 0b001, default: 0b001}
      #
      # options::
      #   principal_name: "User",
      #   permission_name: "Permission"
      #   permissible_name: :permissible
      #
      def acts_as_permissible(permissions, options = nil)
        permissions.freeze
        options ||= {}
        principal = options[:principal_name] || "User"
        permission = options[:permission_name] || "Permission"
        permissible = options[:permissible] || :permissible
        self.define_singleton_method(:all_flags) {permissions}
        self.define_singleton_method(:principal_name) {principal}
        self.define_singleton_method(:permission_name) {permission}
        self.define_singleton_method(:permissible_name) {permissible}

        self.extend ClassMethods
        self.class_eval { class_eval_scope }
      end

      def class_eval_scope
        raise "abstract method"
      end

      module ClassMethods
        def permission_translate(permission)
          @permission_prefix ||= "permission.#{model_name.i18n_key}"
          p = permission.to_s
          I18n.t("#{@permission_prefix}.#{p}", default: p.humanize)
        end

        def permission_label(flag, options = nil)
          options = {restrict: true}.merge(options || {})
          keys = if options[:restrict]
            @inverted_flags ||= flags.invert
            Array(@inverted_flags[flag])
          else
            flags.map {|k, v| k if v & flag == flag}.compact
          end
          keys.map {|k| permission_translate(k)}.join(",") unless keys.empty?
        end

        def permission_options(options = nil)
          options = {translate: true}.merge(options || {})
          translate = options[:translate]
          flags.map {|k, v| [translate ? permission_translate(k) : k, v]}
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

        def to_flags(name_or_value)
          name_or_value.is_a?(Symbol) ? flags(name_or_value) : name_or_value
        end

        def default_flag
          all_flags[:default]
        end
      end
    end

    module ActiveRecordExtension
      extend ActiveSupport::Concern

      included do
        extend Base
        extend Methods
      end

      module Methods
        def class_eval_scope
          principals = principal_name.underscore.pluralize.to_sym
          permissions = permission_name.underscore.pluralize.to_sym
          principal_key = "#{permissions}.#{principal_name.underscore}_id"

          has_many permissions, as: permissible_name, dependent: :destroy,
            after_add: :set_default_flag, extend: AssociationExtensions

          has_many principals, through: permissions

          accepts_nested_attributes_for permissions, allow_destroy: true

          scope :permissible, lambda {|principal_ids, permission = nil|
            includes(permissions).references(permissions).
              where(principal_key => principal_ids).
              where(permission_condition(permission))
          }

          class_eval <<-RUBY
            def authorized_#{principals}(permission)
              self.#{principals}.
                includes(:#{permissions}).references(:#{permissions}).
                where(self.class.permission_condition(permission))
            end

            def authorized?(principal, permission = nil)
              return false unless principal
              self.#{principals}.joins(:#{permissions}).
                where(self.class.permission_condition(permission)).
                exists?("#{principals}.id" => principal)
            end

            private
            def set_default_flag(record)
              record.flags ||= self.class.default_flag
            end
          RUBY
        end

        def permission_condition(permission)
          return nil unless permission
          [
            "#{permission_name.underscore.pluralize}.flags & :f = :f",
            f: flags(permission)
          ]
        end

        module AssociationExtensions
          def add(principal, permission = nil)
            create_or_update(principal) do |p|
              p.flags |= flags(permission) if permission
            end
          end

          def mod(principal, permission)
            create_or_update(principal) do |p|
              p.flags = flags(permission)
            end
          end

          private
          def flags(permission)
            permission.is_a?(Symbol) ?
              proxy_association.owner.class.flags(permission) : permission
          end

          def create_or_update(principal)
            name = proxy_association.owner.class.principal_name.underscore
            p = self.where("#{name}_id" => principal).first || self.build
            p.send("#{name}=", principal)
            yield p
            p.save!
            p
          end
        end
      end
    end

    module MongoidExtension
      extend ActiveSupport::Concern

      included do
        extend Base
        extend Methods
      end

      module Methods
        def class_eval_scope
          principals = principal_name.underscore.pluralize.to_sym
          permissions = permission_name.underscore.pluralize.to_sym
          principal_foreign_key = "#{principal_name.underscore}_id"
          plural_principal_foreign_key = principal_foreign_key.pluralize
          principal_key = "#{permissions}.#{principal_foreign_key}"

          embeds_many permissions, as: permissible_name,
            after_add: :set_default_flag, extend: AssociationExtensions

          index({principal_key: 1, flags: 1})

          accepts_nested_attributes_for permissions, allow_destroy: true

          scope :permissible, lambda {|principal_ids, permission = nil|
            ids = Array(principal_ids).map {|p|
              p.is_a?(Mongoid::Document) ? p.id : p
            }
            cond = { principal_foreign_key => {"$in" => ids } }
            cond[:flags] = {"$all" => split_flag(permission)} if permission
            scoped.and(permissions => { "$elemMatch" => cond })
          }

          class_eval <<-RUBY
            def #{principals}
              ids = #{permissions}.map(&:#{principal_foreign_key})
              #{principal_name}.find(ids)
            end

            def authorized_#{plural_principal_foreign_key}(permission)
              #{permissions}.where(
                flags: {"$all" => self.class.split_flag(permission)}
              ).map(&:#{principal_foreign_key})
            end

            def authorized_#{principals}(permission)
              #{principal_name}.find(authorized_#{plural_principal_foreign_key}(permission))
            end

            def authorized?(principal, permission = nil)
              s = #{permissions}.where(#{principal_foreign_key}: principal)
              s = s.where(flags: {"$all" => self.class.split_flag(permission)}) if permission
              s.exists?
            end

            private
            def set_default_flag(record)
              record.flags ||= self.class.split_flag(self.class.default_flag)
            end
          RUBY
        end

        def split_flag(flag)
          f = flag.is_a?(Symbol) ? flags(flag) : flag
          a = []
          bit = 1
          while f > 0
            a.unshift(bit) if f & 1 == 1
            f >>= 1
            bit <<= 1
          end
          a
        end

        module AssociationExtensions
          def add(principal, permission = nil)
            create_or_update(principal) do |p|
              p.flags |= base.class.to_flags(permission) if permission
            end
          end

          def mod(principal, permission)
            create_or_update(principal) do |p|
              p.flags = flags(permission)
            end
          end

          private
          def flags(permission)
            base.class.split_flag(permission)
          end

          def create_or_update(principal)
            name = base.class.principal_name.underscore
            p = self.where("#{name}_id" => principal).first || self.build
            p.send("#{name}=", principal)
            yield p
            p.save!
            p
          end
        end
      end
    end

    class Railtie < ::Rails::Railtie #:nodoc:
      initializer "acts_as_permissible" do
        ActiveSupport.on_load(:active_record) do
          ::ActiveRecord::Base.send(:include, ActiveRecordExtension)
        end

        begin
          require 'mongoid'
          ::Mongoid::Document.send(:include, MongoidExtension) if defined? ::Mongoid
        rescue LoadError
        end
      end
    end
  end
end
