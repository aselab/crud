module Crud
 class ApplicationController < ::ApplicationController
  [
    Crud::ModelMethods,
    Crud::Authorization,
    Crud::Serialization,
  ].each do |mod|
    include mod
    protected *mod.instance_methods
  end

  helper BootstrapHelper
  helper_method :model, :model_name, :model_key, :resources, :resource, :columns,
    :stored_params, :cancel_path, :column_key?, :association_key?, :sort_key?, :has_nested?,
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

  def index(&format_block)
    do_action
    respond_to do |format|
      format_block.try(:call, format)
      format.any(:html, :js) {}
      format.json { render_json resources }
      format.csv { send_data generate_csv(columns, resources, params), type: "text/csv", filename: params[:filename] }
    end
  end

  def show(&format_block)
    do_action
    respond_to do |format|
      format_block.try(:call, format)
      format.any(:html, :js) {}
      format.json { render_json resource }
    end
  end

  def new(&format_block)
    do_action
    respond_to do |format|
      format_block.try(:call, format)
      format.any(:html, :js) { render_edit }
      format.json { render_json resource }
    end
  end

  def edit(&format_block)
    do_action
    respond_to do |format|
      format_block.try(:call, format)
      format.any(:html, :js) {}
      format.json { render_json resource }
    end
  end

  def create(&format_block)
    result = do_action
    respond_to do |format|
      if result
        format_block.try(:call, format)
        format.any(:html, :js) { redirect_after_success notice: message(:successfully_created, :name => model_name) }
        format.json { render_json resource, status: :created }
      else
        format.any(:html, :js) { render_edit :unprocessable_entity }
        format.json { render_json_errors resource }
      end
    end
  end

  def update(&format_block)
    result = do_action
    respond_to do |format|
      if result
        format_block.try(:call, format)
        format.any(:html, :js) { redirect_after_success notice: message(:successfully_updated, :name => model_name) }
        format.json { render_json resource }
      else
        format.any(:html, :js) { render_edit :unprocessable_entity }
        format.json { render_json_errors resource }
      end
    end
  end

  def destroy(&format_block)
    do_action
    respond_to do |format|
      format_block.try(:call, format)
      format.any(:html, :js) { redirect_after_success notice: message(:successfully_deleted, :name => model_name), status: 303 }
      format.json { head :no_content }
    end
  end

  protected
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

  def search_terms
    tokenize(params[:term])
  end

  def tokenize(word)
    word.to_s.strip.scan(/".*"|[^[[:space:]]]+/).map {|s|
      s.starts_with?('"') && s.ends_with?('"') ? s[1..-2] : s
    }
  end

  def sort_key?(key)
    respond_to?("sort_by_#{key}", true) || column_key?(key) ||
      (activerecord? && association_key?(key))
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
  # オーバーライドして検索結果を返却するように実装する．
  #
  def do_search
    self.columns = columns_for(request.format.symbol) unless request.format.html? || request.format.js?
    association_columns = columns.select {|c| association_key?(c)}

    terms = search_terms
    model_columns = []
    conditions = []
    columns_for_search.each do |c|
      param = params[c] if params[c].present?
      cond = [c, param, model] if param
      if search_method_defined?(c)
        model_columns.push([model, c])
      elsif association = association_class(c)
        association_columns.push(c)
        fields = association.respond_to?(:search_field, true) ?
          association.send(:search_field) :
          [:name, :title].find {|c| column_key?(c, association)}
        Array(fields).each do |f|
          model_columns.push([association, f])
          cond = [f, param, association] if param
        end
      else
        model_columns.push([model, c])
      end
      conditions.push(search_condition_for_column(*cond)) if cond
    end

    include_association(*association_columns)
    r = terms.inject(resources) do |scope, term|
      conds = model_columns.map do |model, column|
        search_condition_for_column(column, term, model)
      end
      cond = if conds.size > 1
        if activerecord?
          "(#{conds.join(" OR ")})"
        elsif mongoid?
          {"$and" => [{"$or" => conds}]}
        end
      else
        conds.first
      end
      scope.where(cond)
    end
    conditions.inject(r) do |scope, cond|
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
  def search_condition_for_column(column, term, model = nil)
    model ||= self.model
    method = "search_by_#{column}"
    if activerecord?
      cond = if respond_to?(method, true)
        model.send(:sanitize_sql_for_conditions, send(method, term))
      else
        c = column_metadata(column, model)
        t = model.arel_table
        if enum_values = enum_values_for(model, column)
          t[c.name].eq(enum_values[term] || term)
        else
          case c.type
          when :string, :text
            t[c.name].matches("%#{term}%")
          when :integer
            t[c.name].eq(Integer(term)) rescue "0 = 1"
          else
            t[c.name].eq(term)
          end
        end
      end
      cond.respond_to?(:to_sql) ? cond.to_sql : cond
    elsif mongoid?
      if respond_to?(method, true)
        send(method, term)
      else
        c = column_metadata(column, model)
        if enum_values = enum_values_for(model, column)
          { c.name => enum_values[term] || term }
        else
          if c.type == String
            { c.name => Regexp.new(Regexp.escape(term)) }
          elsif c.type == Integer
            { c.name => Integer(term) } rescue { id: 0 }
          else
            { c.name => term }
          end
        end
      end
    end
  end

  # enumerize
  def enum_values_for(model, column)
    enum = model.try(:enumerized_attributes).try(:[], column)
    enum && Hash[enum.options]
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
    resources.page(params[:page]).per(params[:per]) unless params[:page] == "false"
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
  # CSV出力に利用するカラムリスト.
  #
  def columns_for_csv
    columns_for(:index)
  end

  #
  # CRUDの画面遷移で保持するパラメータのkey
  #
  def stored_params_keys
    [:controller, :action, :term, :sort_key, :sort_order, :page, :per, :container]
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
    params.symbolize_keys.extract!(*keys).merge(overwrites)
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
    @remote = request.format.js?
  end

  def cancel_path
    url_for(stored_params(action: :index))
  end

  def set_redirect_to(url)
    @redirect_to_url = url
  end

  # 作成，更新，削除成功後のリダイレクト先
  def redirect_after_success(options)
    redirect_to(@redirect_to_url || cancel_path, options)
  end

  def message(key, options = nil)
    @message || t("crud.message." + key.to_s, options)
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

  def render_edit(status = :ok)
    render action: "edit", status: status
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
 end
end
