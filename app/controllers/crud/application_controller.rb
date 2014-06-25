module Crud
 class ApplicationController < ::ApplicationController
  helper BootstrapHelper
  helper_method :model, :model_name, :model_key, :resources, :resource, :columns,
    :stored_params, :column_key?, :association_key?, :sort_key?, :nested?,
    :sort_key, :sort_order, :index_actions, :column_type, :can?, :cannot?

  before_action :set_defaults, :only => [:index, :show, :new, :edit, :create, :update]
  before_action :before_index, :only => :index
  before_action :before_show, :only => :show
  before_action :before_new, :only => :new
  before_action :before_edit, :only => :edit
  before_action :before_create, :only => :create
  before_action :before_update, :only => :update
  before_action :before_destroy, :only => :destroy
  before_action :authorize_action

  class_attribute :_permit_keys

  def index
    do_index
    respond_to do |format|
      format.html # index.html.erb
      format.json { render_json resources }
    end
  end

  def show
    do_action
    respond_to do |format|
      format.html { render_show }
      format.json { render_json resource }
    end
  end

  def new
    assign_params if params[model_key].present?
    do_action
    respond_to do |format|
      format.html { render_edit }
      format.json { render_json resource }
    end
  end

  def edit
    do_action
    render_edit
  end

  def create
    assign_params
    result = do_create
    if result && request.xhr?
      render_json resource, status: :created
      return
    end

    respond_to do |format|
      if result
        format.html { redirect_after_success notice: message(:successfully_created, :name => model_name) }
        format.json { render_json resource, status: :created }
      else
        format.html { render_edit :unprocessable_entity }
        format.json { render json: resource.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    assign_params
    result = do_update
    if result && request.xhr?
      render_json resource
      return
    end

    respond_to do |format|
      if result
        format.html { redirect_after_success notice: message(:successfully_updated, :name => model_name) }
        format.json { render_json resource }
      else
        format.html { render_edit :unprocessable_entity }
        format.json { render json: resource.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    do_action
    respond_to do |format|
      format.html { redirect_after_success notice: message(:successfully_deleted, :name => model_name) }
      format.json { head :no_content }
    end
  end

  protected
  attr_accessor :columns, :index_actions
  attr_writer :resources, :resource

  def resources
    @resources ||= model.all
  end

  def resource
    @resource ||= find_resource
  end

  def self.permit_keys(*keys)
    self._permit_keys ||= []
    self._permit_keys += keys unless keys.empty?
    self._permit_keys
  end

  def permit_params
    params.require(model_key).permit(self.class.permit_keys)
  end

  def activerecord?
    if @is_activerecord.nil?
      @is_activerecord =
        !!(defined?(ActiveRecord::Base) && model <= ActiveRecord::Base)
    end
    @is_activerecord
  end

  def mongoid?
    if @is_mongoid.nil?
      @is_mongoid =
        !!(defined?(Mongoid::Document)) && model.include?(Mongoid::Document)
    end
    @is_mongoid
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
    value ? @default_sort_key = value : @default_sort_key
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
    value ? @default_sort_order = value : @default_sort_order
  end

  #
  #=== CRUD対象のモデルクラス
  #
  # デフォルトではコントローラクラス名から対応するモデルを自動選択する．
  # 名前が一致しない場合はオーバーライドしてモデルの参照を返すように実装する．
  #
  def model
    @model ||= self.class.name.sub(/Controller$/, "").singularize.constantize
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

  def serializer
    @serializer ||=
      ("#{model.name}Serializer".constantize rescue nil) ||
      Crud::DefaultSerializer
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
    @model_columns ||= self.class.permit_keys
  end

  def search_terms
    tokenize(params[:term])
  end

  def tokenize(word)
    word.to_s.strip.scan(/".*"|[^[[:space:]]]+/).map {|s|
      s.starts_with?('"') && s.ends_with?('"') ? s[1..-2] : s
    }
  end

  def column_metadata(name, model = model)
    if activerecord?
      model.columns_hash[name.to_s]
    elsif mongoid?
      model.fields[name.to_s]
    end
  end

  def column_type(name, model = model)
    type = column_metadata(name, model).try(:type)
    type.is_a?(Class) ? type.name.downcase.to_sym : type
  end

  def column_key?(key, model = model)
    !!column_metadata(key, model)
  end

  def association_key?(key, model = model)
    !!model.reflect_on_association(key.to_sym)
  end

  def association_class(key, model = model)
    model.reflect_on_association(key.to_sym).try(:klass)
  end

  def sort_key?(key)
    respond_to?("sort_by_#{key}", true) || column_key?(key) ||
      (activerecord? && association_key?(key))
  end

  def nested?
    if activerecord?
      columns_for(crud_action).any? do |c|
        model.nested_attributes_options.has_key?(c)
      end
    elsif mongoid?
      columns_for(crud_action).any? do |c|
        model.nested_attributes.has_key?(c.to_s + "_attributes")
      end
    end
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
    action = crud_action
    if authorization.respond_to?(action)
      authorization.send(action)
    else
      raise NotAuthorizedError unless can? action, resource
    end
  end

  def authorization
    @authorization ||= (self.class::Authorization rescue DefaultAuthorization).new(current_user)
  end

  # 権限がある場合にtrueを返す。
  def can?(action, resource)
    authorization.can?(action, resource)
  end

  # can?の逆
  def cannot?(action, resource)
    !can?(action, resource)
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
    if ids = params[:except_ids]
      if activerecord?
        resources.where.not("#{model.table_name}.id" => ids)
      elsif mongoid?
        resources.not_in(id: ids)
      end
    end
  end

  #
  # indexアクションで呼び出される内部メソッド.
  # オーバーライドして検索結果を返却するように実装する．
  #
  def do_search
    format = (params[:format] || :html).to_sym
    columns = format == :html ? columns_for(:index) : columns_for(format)
    association_columns = columns.select {|c| association_key?(c)}

    terms = search_terms
    model_columns = []
    columns_for_search.each do |c|
      if search_method_defined?(c)
        model_columns.push([model, c])
      elsif association = association_class(c)
        association_columns.push(c)
        fields = association.respond_to?(:search_field, true) ?
          association.send(:search_field) :
          [:name, :title].find {|c| column_key?(c, association)}
        Array(fields).each {|f| model_columns.push([association, f])}
      else
        model_columns.push([model, c])
      end
    end

    include_association(*association_columns)
    terms.inject(resources) do |scope, term|
      conds = model_columns.map {|model, column|
        search_condition_for_column(column, term, model)
      }
      cond = if conds.size > 1
        if activerecord?
          "(#{conds.join(" OR ")})"
        elsif mongoid?
          {"$or" => conds}
        end
      else
        conds.first
      end
      scope.where(cond)
    end
  end

  def include_association(*associations)
    return if associations.empty?
    if activerecord?
      self.resources = resources.includes(associations).references(associations)
    elsif mongoid?
      associations.select! do |a|
        !model.reflect_on_association(a).relation.embedded?
      end
      self.resources = resources.includes(associations)
    end
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

  #
  # search_by_:column_name という名前のメソッドを定義すると、
  # カラム毎の検索条件をカスタマイズできる。
  # whereに渡す条件式を返すように実装する。
  #
  #  def search_by_name(term)
  #    ["users.lastname like ? and users.firstname ?", "%#{term}%", "%#{term}%"]
  #  end
  #
  def search_condition_for_column(column, term, model = model)
    method = "search_by_#{column}"
    if activerecord?
      cond = if respond_to?(method, true)
        model.where(send(method, term)).where_values.first
      else
        c = column_metadata(column, model)
        t = model.arel_table
        case c.type
        when :string, :text
          t[c.name].matches("%#{term}%")
        when :integer
          t[c.name].eq(Integer(term)) rescue "0 = 1"
        else
          t[c.name].eq(term)
        end
      end
      cond.respond_to?(:to_sql) ? cond.to_sql : cond
    elsif mongoid?
      if respond_to?(method, true)
        send(method, term)
      else
        c = column_metadata(column, model)
        if c.type == String
          { c.name => Regexp.new(term) }
        elsif c.type == Integer
          { c.name => Integer(term) } rescue { id: 0 }
        else
          { c.name => term }
        end
      end
    end
  end

  #
  # sort_by_:column_name という名前のメソッドを定義すると、
  # カラム毎のソート条件をカスタマイズできる。
  #
  #  def sort_by_name(order)
  #    "users.last_name #{order}, users.first_name #{order}"
  #  end
  #
  def sort_condition_for_column(name)
    method = "sort_by_#{name}"
    if respond_to?(method, true)
      send(method, sort_order)
    elsif activerecord?
      column = if association = association_class(name)
        include_association(name)
        f = association.respond_to?(:sort_field, true) ?
          association.send(:sort_field) :
          [:name, :title, :id].find {|c| column_key?(c, association)}
        "#{association.table_name}.#{f.to_s}" if f
      else
        c = column_metadata(name)
        "#{model.table_name}.#{c.name}" if c
      end
      "#{column} #{sort_order}" if column
    elsif mongoid?
      { name => sort_order }
    end
  end

  def do_sort
    return unless key = sort_key
    if cond = sort_condition_for_column(key)
      if activerecord?
        resources.order(cond) 
      elsif mongoid?
        resources.order_by(cond) 
      end
    end
  end

  def do_page
    resources.page(params[:page]).per(params[:per])
  end

  #
  # indexメソッドで呼び出される内部メソッド.
  #
  def do_index
    self.resources = do_filter || resources
    self.resources = do_search || resources
    self.resources = do_sort || resources
    self.resources = do_page || resources
  end

  #
  # createメソッドで呼び出される内部メソッド.
  # resourceに格納されているレコードの保存処理を行い，
  # 結果をBooleanで返すように実装する．
  #
  def do_create
    resource.save
  end

  #
  # updateメソッドで呼び出される内部メソッド.
  # resourceに格納されているレコードの更新処理を行い，
  # 結果をBooleanで返すように実装する．
  #
  def do_update
    resource.save
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
    resource.assign_attributes(permit_params)
  end

  def find_resource
    find_resource! if params[:id]
  end

  def find_resource!
    model.find(params[:id])
  end

  def columns_for(action)
    column_method = "columns_for_" + action.to_s
    self.respond_to?(column_method, true) ?  self.send(column_method) : model_columns
  end

  #
  # 検索に利用するカラムリスト.
  # デフォルトではindexで表示する項目のうちtypeがstring, text, integerであるものまたは関連
  #
  def columns_for_search
    columns_for(:index).select {|c| search_column?(model, c)}
  end

  def search_method_defined?(column_name)
    respond_to?("search_by_#{column_name}", true)
  end

  def search_column?(model, column_name)
    return true if search_method_defined?(column_name)
    type = column_type(column_name)
    (type && [:string, :text, :integer].include?(type)) ||
      (activerecord? && association_key?(column_name))
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
  # CRUDの画面遷移で保持するパラメータのkey
  #
  def stored_params_keys
    [:controller, :action, :term, :sort_key, :sort_order, :page, :per]
  end

  #
  # 保持するパラメータ
  #
  # stored_params => stored_params_keysに一致するパラメータのみ返す
  # stored_params(:a, :b) => :a, :bのパラメータのみ返す
  # stored_params(:a, :b, :c => 1, :d => 2) => :a, :bのパラメータに{:c => 1, :d => 2}をマージした結果を返す
  #
  def stored_params(*args)
    overwrites = args.extract_options!
    keys = args.blank? ? stored_params_keys : args
    params.dup.extract!(*keys).merge(overwrites)
  end

  def crud_action
    @crud_action ||= case action = params[:action].to_sym
    when :new then :create
    when :edit then :update
    else action
    end
  end

  def index_actions
    [:show, :edit, :destroy]
  end

  def set_defaults
    @title = t("crud.action_title." + crud_action.to_s, :name => model_name)
    self.columns = columns_for(crud_action)
    self.index_actions = index_actions
  end

  def set_redirect_to(url)
    @redirect_to_url = url
  end

  # 作成，更新，削除成功後のリダイレクト先
  def redirect_after_success(options)
    redirect_to(@redirect_to_url || stored_params(:action => :index), options)
  end

  def message(key, options = nil)
    @message || t("crud.message." + key.to_s, options)
  end

  def serialization_scope
    {
      current_user: current_user,
      authorization: authorization,
      columns: columns_for_json
    }
  end

  def render_json(items, options = nil)
    options ||= {}
    options[:json] = items
    options[:scope] = serialization_scope
    options[:root] = false

    if items.is_a?(Kaminari::PageScopeMethods)
      options[:each_serializer] = serializer
      options[:root] = "items"
      options[:meta] = {
        per_page: items.limit_value,
        total_count: items.total_count,
        total_pages: items.total_pages,
        current_page: items.current_page
      }
    elsif items.respond_to?(:to_ary)
      options[:each_serializer] = serializer
    else
      options[:serializer] = serializer
    end
    render options
  end

  def render_show
    if request.xhr?
      render action: "ajax_show", layout: false
    else
      render action: "show"
    end
  end


  def render_edit(status = :ok)
    if request.xhr?
      @skip_form_actions = true
      render action: "ajax_edit", layout: false, status: status
    else
      render action: "edit", status: status
    end
  end

  unless method_defined?(:current_user)
    define_method(:current_user) {}
  end

  def before_index
  end

  def before_show
  end

  def before_new
    self.resource = new_resource
  end

  def before_edit
  end

  def before_create
    self.resource = new_resource
  end

  def before_update
  end

  def before_destroy
  end

  class DefaultAuthorization
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
