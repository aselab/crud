module Crud
  module Authorization
    extend ActiveSupport::Concern

    included do
      unless method_defined?(:current_user)
        define_method(:current_user) {}
      end
    end

    def authorize_for(action, resource)
      if authorization.respond_to?(action)
        authorization.send(action)
      else
        raise NotAuthorizedError unless can? action, resource
      end
    end

    def authorization
      @authorization ||= begin
        name = self.class.name
        auth = "#{name}::Authorization".safe_constantize # コントローラのインナークラス
        auth ||= name.sub(/Controller$/, "Authorization").safe_constantize if name.ends_with?("Controller") # コントローラと同名のAuthorizationクラス
        auth ||= Default
        auth.new(current_user)
      end
    end

    # 権限がある場合にtrueを返す。
    def can?(action, resource)
      authorization.can?(action, resource)
    end

    # can?の逆
    def cannot?(action, resource)
      !can?(action, resource)
    end

    # デフォルト権限
    class Default
      extend Memoist
      attr_reader :current_user

      def initialize(user)
        @current_user = user
      end

      def index
      end

      # 各アクションの権限は def update?(resource) のようなメソッドを定義し、
      # true or falseを返すように実装する。定義しない場合のデフォルトはtrueである。
      def can?(action, resource)
        method = action.to_s + "?"
        respond_to?(method) ? send(method, resource) : true
      end

      def new?(resource)
        can? :create, resource
      end

      def edit?(resource)
        can? :update, resource
      end

      def create?(resource)
        can? :manage, resource
      end

      def update?(resource)
        can? :manage, resource
      end

      def destroy?(resource)
        can? :manage, resource
      end

      memoize :can?
    end
  end
end
