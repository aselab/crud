module Crud
  class ApiController < ::ApplicationController
    include ActionController::MimeResponds

    [
      Crud::ModelMethods,
      Crud::Authorization,
      Crud::Serialization,
    ].each do |mod|
      include mod
      protected *mod.instance_methods
    end

    before_action :set_defaults, only: [:index, :show, :new, :edit, :create, :update]
    before_action :before_index, only: :index
    before_action :before_show, only: :show
    before_action :before_new, only: :new
    before_action :before_edit, only: :edit
    before_action :before_create, only: :create
    before_action :before_update, only: :update
    before_action :before_destroy, only: :destroy
    before_action :authorize_action

    def index(&format_block)
      do_action
      respond_to do |format|
        format_block.try(:call, format)
        format.json { render_json resources }
        format.csv { send_data generate_csv(columns, resources, params), type: "text/csv", filename: params[:filename] }
      end
    end

    def show(&format_block)
      do_action
      respond_to do |format|
        format_block.try(:call, format)
        format.json { render_json resource }
      end
    end

    def new(&format_block)
      do_action
      respond_to do |format|
        format_block.try(:call, format)
        format.json { render_json resource }
      end
    end

    def edit(&format_block)
      do_action
      respond_to do |format|
        format_block.try(:call, format)
        format.json { render_json resource }
      end
    end

    def create(&format_block)
      result = do_action
      respond_to do |format|
        respond_with_condition(format_block, format, result)
        if result
          format.json { render_json resource, status: :created }
        else
          format.json { render_json_errors resource }
        end
      end
    end

    def update(&format_block)
      result = do_action
      respond_to do |format|
        respond_with_condition(format_block, format, result)
        if result
          format.json { render_json resource }
        else
          format.json { render_json_errors resource }
        end
      end
    end

    def destroy(&format_block)
      result = do_action
      respond_to do |format|
        respond_with_condition(format_block, format, result)
        if result
          format.json { head :no_content }
        else
          format.json { render_json_errors resource }
        end
      end
    end

    protected
    class_attribute :_default_sort_key, :_default_sort_order
    attr_writer :resources, :resource, :columns

    #
    #=== CRUD対象のモデルクラス
    #
    # デフォルトではコントローラクラス名から対応するモデルを自動選択する．
    # 名前が一致しない場合はオーバーライドしてモデルの参照を返すように実装する．
    #
    def model
      @model ||= self.class.name.sub(/Controller$/, "").singularize.constantize
    end

    def resources
      @resources ||= model.all
    end

    def resource
      @resource ||= find_resource
    end

    def columns
      @columns ||= columns_for(crud_action)
    end

    #
    #=== デフォルトのソートキー
    #
    # コントローラごとにsort_keyが指定されていない場合のデフォルト値を設定できる
    #
    #  class SampleController < Crud::ApplicationController
    #    default_sort_key :name
    #    default_sort_order :desc
    #  end
    #
    def self.default_sort_key(value = nil)
      value ? self._default_sort_key = value : _default_sort_key
    end

    #
    #=== デフォルトのソート順
    #
    # コントローラごとにsort_orderが指定されていない場合のデフォルト値を設定できる
    #
    #  class SampleController < Crud::ApplicationController
    #    default_sort_key :name
    #    default_sort_order :desc
    #  end
    #
    def self.default_sort_order(value = nil)
      value ? self._default_sort_order = value : _default_sort_order
    end

    def sort_key?(key)
      respond_to?("sort_by_#{key}", true) || reflection.column_key?(key) ||
        (activerecord? && reflection.association_key?(key))
    end

    #
    #=== 権限チェック
    #
    # Authorizationクラスにaction名と同じメソッドを定義すると、
    # 各アクションの権限処理をオーバーライドできる。
    # その場合は権限がないときCrud::NotAuthorizedErrorを投げるように実装する。
    # デフォルトでは can? メソッドを呼び出して権限がない場合例外を投げるようになっている。
    #
    def authorize_action
      authorize_for(crud_action, resource)
    end

    #
    #=== アクション実行
    #
    # do_:action という名前のメソッドを定義すると、
    # アクションごとの処理をオーバーライドできる。
    #
    def do_action
      method = "do_" + params[:action]
      send(method) if respond_to?(method, true)
    end

    #
    # indexアクションで呼び出される内部メソッド。
    # 権限によって検索対象を絞り込みたい場合などは、
    # これをオーバーライドして実装する。
    #
    def do_filter
      if ids = params[:ids] || params[:except_ids]
        ids = ids.split(",")
        if activerecord?
          cond = {"#{model.table_name}.id" => ids}
          params[:ids] ? resources.where(cond) : resources.where.not(cond)
        elsif mongoid?
          params[:ids] ? resources.in(id: ids) : resources.not_in(id: ids)
        end
      else
        resources
      end
    end

    #
    # indexアクションで呼び出される内部メソッド.
    # オーバーライドして検索ソートした結果を返却するように実装する．
    #
    def do_query
      query = SearchQuery.new(resources, columns_for_search, self)
      query.keyword_search(search_keyword)
      query.advanced_search(search_values, search_operators)
      query.sort(sort_key, sort_order) if sort_key
      query.scope
    end

    def search_keyword
      params[:term]
    end

    def search_operators
      params[:op] || {}
    end

    def search_values
      @search_values ||= begin
        p = params[:v] || params[:value]
        if p.is_a?(ActionController::Parameters)
          p.to_unsafe_hash
        else
          columns_for_advanced_search.each_with_object({}) do |column, h|
            h[column] = params[column] if params.has_key?(column)
          end
        end
      end
    end

    def advanced_search?
      search_values.present? || search_operators.present?
    end

    def sort_key
      (params[:sort_key] || self.class.default_sort_key).try(:to_sym)
    end

    def sort_order
      case params[:sort_order]
      when "asc", "desc"
        params[:sort_order]
      else
        self.class.default_sort_order || :asc
      end.to_sym
    end

    def do_page
      resources.page(params[:page]).per(params[:per]) unless params[:page] == "false"
    end

    #
    # indexメソッドで呼び出される内部メソッド.
    #
    def do_index
      self.resources = do_filter || resources
      self.resources = do_query || resources
      self.resources = do_page || resources
    end

    #
    # createメソッドで呼び出される内部メソッド.
    # resourceに格納されているレコードの保存処理を行い，
    # 結果をBooleanで返すように実装する．
    #
    def do_create
      resource.update_attributes(permit_params)
    end

    #
    # updateメソッドで呼び出される内部メソッド.
    # resourceに格納されているレコードの更新処理を行い，
    # 結果をBooleanで返すように実装する．
    #
    def do_update
      resource.update_attributes(permit_params)
    end

    #
    # destroyメソッドで呼び出される内部メソッド.
    # resourceに格納されている対象レコードに対して削除処理を行うように実装する．
    #
    def do_destroy
      resource.destroy
    end

    def new_resource
      model.new
    end

    def assign_params
      return unless params[model_key]
      options ||= {}
      p = permit_params
      # 関連は除外
      hash_keys = permit_keys.select {|key| key.is_a?(Hash)}
      hash_keys.each do |hash|
        hash.keys.each {|key| p.delete(key)}
      end
      resource.assign_attributes(p)
    end

    def find_resource
      find_resource! if params[:id]
    end

    def find_resource!
      model.find(params[:id])
    end

    def columns_for_index
      columns_for(request.format.symbol)
    end

    #
    # 検索に利用するカラムリスト.
    # デフォルトではindexで表示する項目のうちtypeがstring, text, integerであるものまたは関連
    #
    def columns_for_search
      columns_for(:index).select {|c| search_column?(model, c)}
    end

    #
    # 詳細検索に利用するカラムリスト.
    #
    def columns_for_advanced_search
      columns_for_search
    end

    def search_method_defined?(column_name)
      respond_to?("search_by_#{column_name}", true)
    end

    def search_column?(model, column_name)
      return true if search_method_defined?(column_name)
      type = reflection(model).column_type(column_name)
      (type && [:enum, :string, :text, :integer, :float].include?(type)) ||
        (activerecord? && reflection(model).association_key?(column_name))
    end

    #
    # JSON出力に利用するカラムリスト.
    #
    def columns_for_json
      if params[:action] == "new"
        columns_for(crud_action)
      else
        [:id] + columns_for(crud_action)
      end
    end

    #
    # CSV出力に利用するカラムリスト.
    #
    def columns_for_csv
      columns_for(:index)
    end

    def crud_action
      @crud_action ||= case action = params[:action].to_sym
      when :new then :create
      when :edit then :update
      else action
      end
    end

    def serializer
      @serializer ||=
        ("#{model.name}Serializer".constantize rescue nil) || super
    end

    def serialization_scope
      {
        action: params[:action],
        current_user: current_user,
        authorization: authorization,
        columns: columns_for_json
      }
    end

    def render_json(items, options = nil)
      render json_options(items, options)
    end

    def render_json_errors(item)
      render json_errors_options(item)
    end

    def set_defaults
    end

    def before_index
      self.resource = new_resource
    end

    def before_show
    end

    def before_new
      self.resource = new_resource
      assign_params
    end

    def before_edit
      assign_params
    end

    def before_create
      self.resource = new_resource
      assign_params
    end

    def before_update
      assign_params
    end

    def before_destroy
    end

    def respond_with_condition(block, format, condition)
      case block.try(:arity)
      when 2
        if condition
          block.call(format, nil)
        else
          block.call(nil, format)
        end
      when 1
        block.call(format) if condition
      end
    end
  end
end
