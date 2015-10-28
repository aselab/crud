module Crud
  module ModelMethods
    extend ActiveSupport::Concern

    included do
      class_attribute :_permit_keys
    end

    def activerecord?
      if @is_activerecord.nil?
        @is_activerecord = self.class.activerecord?(model)
      end
      @is_activerecord
    end

    def mongoid?
      if @is_mongoid.nil?
        @is_mongoid = self.class.mongoid?(model)
      end
      @is_mongoid
    end

    def model
      raise "model method must be implemented in subclass"
    end

    #
    #=== モデル名
    #
    # viewでの表示に利用される．デフォルトではmodel_name.humanが用いられる．
    #
    def model_name
      @model_name ||= model.model_name.human
    end

    #
    #=== モデルのキー
    #
    # paramsからデータを取得する時に用いるキー．デフォルトはscaffoldと同様．
    # 
    def model_key
      @model_key ||= model.model_name.param_key.to_sym
    end

    #
    #=== 表示/更新対象のカラムリスト
    #
    # デフォルト値はpermit_keys全て．
    # 変更したい場合はオーバーライドして対象カラム名の配列を返すように実装する．
    # アクションごとに対象カラムを変更したい場合はcolumns_for_:action という
    # 名前のメソッドを定義するとそちらが優先される．
    #
    def model_columns
      @model_columns ||= self.class.permit_keys.flat_map {|key| key.is_a?(Hash) ? key.keys : key}
    end

    def columns_for(action)
      column_method = "columns_for_" + action.to_s
      self.respond_to?(column_method, true) ?  self.send(column_method) : model_columns
    end

    def permit_keys
      self.class.permit_keys
    end

    def permit_params
      keys = permit_keys
      # 編集時のパラメータ渡しで関連がsaveされるのを抑制
      if activerecord? && params[:action] == "edit"
        hash_keys, keys = keys.partition {|key| key.is_a?(Hash)}
        keys -= hash_keys.flat_map(&:keys)
      end
      params.require(model_key).permit(keys)
    end

    def column_metadata(name, model = nil)
      model ||= self.model
      if activerecord?
        model.columns_hash[name.to_s]
      elsif mongoid?
        model.fields[name.to_s]
      end
    end

    def column_type(name, model = nil)
      model ||= self.model
      type = column_metadata(name, model).try(:type)
      type.is_a?(Class) ? type.name.downcase.to_sym : type
    end

    def column_key?(key, model = nil)
      model ||= self.model
      !!column_metadata(key, model)
    end

    def association_key?(key, model = nil)
      model ||= self.model
      !!model.reflect_on_association(key.to_sym)
    end

    def association_class(key, model = nil)
      model ||= self.model
      model.reflect_on_association(key.to_sym).try(:klass)
    end

    def has_nested?(action, model = nil)
      model ||= self.model
      if activerecord?
        columns_for(action).any? do |c|
          model.nested_attributes_options.has_key?(c)
        end
      elsif mongoid?
        columns_for(action).any? do |c|
          model.nested_attributes.has_key?(c.to_s + "_attributes")
        end
      end
    end

    module ClassMethods
      def permit_keys(*keys)
        self._permit_keys ||= []
        keys.each do |key|
          self._permit_keys.push(key)
          self._permit_keys += key.keys if key.is_a?(Hash)
        end
        self._permit_keys
      end

      def activerecord?(item)
        return false unless defined?(ActiveRecord::Base)
        item = item.class unless item.is_a?(Class)
        !!(item <= ActiveRecord::Base)
      end

      def mongoid?(item)
        return false unless defined?(Mongoid::Document)
        item = item.class unless item.is_a?(Class)
        item.include?(Mongoid::Document)
      end
    end
  end
end
