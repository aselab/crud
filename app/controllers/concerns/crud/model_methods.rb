module Crud
  module ModelMethods
    extend ActiveSupport::Concern

    included do
      protected
      class_attribute :_permit_keys
      delegate :activerecord?, :mongoid?, to: :reflection
    end

    def reflection(model = nil)
      ModelReflection[model || self.model]
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
      return {} unless params[model_key]
      params.require(model_key).permit(permit_keys).to_unsafe_h.with_indifferent_access
    end

    module ClassMethods
      def permit_keys(*keys)
        self._permit_keys ||= []
        keys.flatten.each do |key|
          self._permit_keys.push(key)
          self._permit_keys += key.keys if key.is_a?(Hash)
        end
        self._permit_keys
      end
    end
  end
end
