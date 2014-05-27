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

      def permission_condition(permission)
        raise "abstract method"
      end

      module ClassMethods
        def permission_translate(permission)
          @permission_prefix ||= "permission.#{model_name.i18n_key}"
          p = permission.to_s
          I18n.t("#{@permission_prefix}.#{p}", default: p.humanize)
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
    end

    module ActiveRecordExtension
      include Base

      def class_eval_scope
        principals = principal_name.underscore.pluralize.to_sym
        permissions = permission_name.underscore.pluralize.to_sym

        has_many permissions, as: permissible_name, dependent: :destroy,
          after_add: :set_default_flag, extend: AssociationExtensions

        has_many principals, through: permissions

        accepts_nested_attributes_for permissions, allow_destroy: true

        scope permissible_name, lambda {|principal_ids, permission|
          includes(permissions).references(permissions).
            where("#{permissions}.#{principal_name.underscore}_id" => principal_ids).
            where(permission_condition(permission))
        }

        class_eval <<-RUBY
          def authorized_#{principals}(permission)
            self.#{principals}.
              includes(:#{permissions}).references(:#{permissions}).
              where(self.class.permission_condition(permission))
          end

          private
          def set_default_flag(record)
            record.flags ||= self.class.default_flag
          end
        RUBY
      end

      def permission_condition(permission)
        ["permissions.flags & :f = :f", f: flags(permission)]
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

    class Railtie < ::Rails::Railtie #:nodoc:
      initializer "acts_as_permissible" do
        ActiveSupport.on_load(:active_record) do
          ::ActiveRecord::Base.extend ActiveRecordExtension
        end
      end
    end
  end
end
