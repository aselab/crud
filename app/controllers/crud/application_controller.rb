class Crud::ApplicationController < ApplicationController
  helper Crud::BootstrapHelper
  helper_method :model, :model_name, :model_key, :resources, :resource, :columns,
    :stored_params, :column_key?, :association_key?, :sort_key?, :nested?,
    :sort_key, :sort_order

  before_filter :set_defaults, :only => [:index, :show, :new, :edit, :create, :update]
  before_filter :before_index, :only => :index
  before_filter :before_show, :only => :show
  before_filter :before_new, :only => :new
  before_filter :before_edit, :only => :edit
  before_filter :before_create, :only => :create
  before_filter :before_update, :only => :update
  before_filter :before_destroy, :only => :destroy

  def index
    respond_to do |format|
      format.html # index.html.erb
      format.json { render_json resources }
    end
  end

  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: resource }
    end
  end

  def new
    respond_to do |format|
      format.html { render_edit }
      format.json { render json: resource }
    end
  end

  def edit
    render_edit
  end

  def create
    result = do_create
    if result && request.xhr?
      render json: resource, status: :created, location: resource
      return
    end

    respond_to do |format|
      if result
        format.html { redirect_after_success notice: message(:successfully_created, :name => model_name) }
        format.json { render json: resource, status: :created, location: resource }
      else
        format.html { render_edit :unprocessable_entity }
        format.json { render json: resource.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    result = do_update
    if result && request.xhr?
      render json: resource
      return
    end

    respond_to do |format|
      if result
        format.html { redirect_after_success notice: message(:successfully_updated, :name => model_name) }
        format.json { render json: resource }
      else
        format.html { render_edit :unprocessable_entity }
        format.json { render json: resource.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      format.html { redirect_after_success notice: message(:successfully_deleted, :name => model_name) }
      format.json { head :no_content }
    end
  end

  protected
  attr_accessor :resources, :resource, :columns

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

  #
  #=== 表示/更新対象のカラムリスト
  #
  # デフォルト値はaccessible_attributes全て．
  # 変更したい場合はオーバーライドして対象カラム名の配列を返すように実装する．
  # アクションごとに対象カラムを変更したい場合はcolumns_for_:action という
  # 名前のメソッドを定義するとそちらが優先される．
  #
  def model_columns
    @model_columns ||=
      model.accessible_attributes.to_a.reject(&:blank?).map(&:to_sym)
  end

  def search_terms
    tokenize(params[:term])
  end

  def tokenize(word)
    word.to_s.strip.scan(/".*"|[^[[:space:]]]+/).map {|s|
      s.starts_with?('"') && s.ends_with?('"') ? s[1..-2] : s
    }
  end

  def column_key?(key)
    model.columns_hash.has_key?(key.to_s)
  end

  def association_key?(key)
    model.reflections.has_key?(key.to_sym)
  end

  def sort_key?(key)
    respond_to?("sort_by_#{key}", true) || column_key?(key) || association_key?(key)
  end

  def nested?
    columns_for(crud_action).any? {|c|
      model.nested_attributes_options.has_key?(c)
    }
  end

  #
  #=== 権限チェック
  #
  # デフォルトでは authorize! :action, resource でチェックする。
  # authorize_:actionという名前のメソッドを定義すると、
  # アクションごとの権限チェック処理をオーバーライドできる。
  #
  def authorize_action
    method = "authorize_" + crud_action.to_s
    if respond_to?(method, true)
      send(method)
    else
      authorize! crud_action, resource
    end
  end

  def authorize_index
    authorize! :index, model
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
  # indexアクションで呼び出される内部メソッド.
  # オーバーライドしてself.resourcesに表示対象を格納するように実装する．
  #
  def do_search
    format = (params[:format] || :html).to_sym
    columns = format == :html ? columns_for(:index) : columns_for(format)
    associations, columns = columns.partition {|c| association_key?(c)}
    all_columns_exist = columns.all? {|c| column_key?(c)}

    self.resources = (associations.empty? && all_columns_exist) ?
        model.accessible_by(current_ability, :read) :
        model.includes(associations).accessible_by(current_ability, :read)

    search_by_sql
  end

  def do_filter
    if ids = params[:except_ids]
      self.resources = resources.where(["#{model.table_name}.id not in (?)", ids])
    end
  end

  def search_by_sql
    terms = search_terms

    model_columns = []
    columns_for_search.each {|c|
      reflection = model.reflections[c.to_sym]
      if reflection
        self.resources = resources.includes(c.to_sym)
        association = reflection.class_name.constantize
        fields = association.respond_to?(:search_field, true) ?
          association.send(:search_field) :
          [:name, :title].find {|c| association.columns_hash.has_key?(c.to_s)}
        Array(fields).each {|f| model_columns.push([association, f])}
      else
        model_columns.push([model, c])
      end
    }
    self.resources = resources.where(build_query(model_columns, terms))
  end

  def build_query(model_columns, terms)
    return nil if model_columns.empty? || terms.empty?

    terms.map {|term|
      conds = model_columns.map {|model, column|
        search_sql_for_column(model, column, term)
      }.compact
      conds.size > 1 ? "(#{conds.join(" OR ")})" : conds.first
    }.compact.join(" AND ")
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
  #
  #  def search_by_name(term)
  #    ["users.lastname like ? and users.firstname ?", "%#{term}%", "%#{term}%"]
  #  end
  #
  def search_sql_for_column(model, column, term)
    method = "search_by_#{column}"
    if respond_to?(method, true)
      model.send(:sanitize_sql_for_conditions, send(method, term), model.table_name)
    else
      c = model.columns_hash[column.to_s]
      column_name = "#{model.table_name}.#{c.name}"
      case c.type
      when :string, :text
        model.send(:sanitize_sql_array, ["#{column_name} like ?", "%#{term}%"])
      when :integer
        model.send(:sanitize_sql_hash, column_name => Integer(term)) rescue "0 = 1"
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
  def sort_sql_for_column(name)
    method = "sort_by_#{name}"
    if respond_to?(method, true)
      send(method, sort_order)
    else
      column = if reflection = model.reflections[name]
        self.resources = resources.includes(name)
        association = reflection.class_name.constantize
        f = association.respond_to?(:sort_field, true) ?
          association.send(:sort_field) :
          [:name, :title, :id].find {|c| association.columns_hash.has_key?(c.to_s)}
        "#{association.table_name}.#{f.to_s}" if f
      else
        c = model.columns_hash[name.to_s]
        "#{model.table_name}.#{c.name}" if c
      end
      "#{column} #{sort_order}" if column
    end
  end

  def do_sort
    return unless key = sort_key
    sql = sort_sql_for_column(key)
    self.resources = resources.order(sql) if sql
  end

  def do_page
    self.resources = resources.page(params[:page]).per(params[:per])
  end

  #
  # indexメソッドで呼び出される内部メソッド.
  #
  def do_index
    do_search
    do_filter
    do_sort
    do_page
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

  #
  # Mass-Assignmentスコープ.
  # 必要であればオーバーライドしてスコープシンボルを返すように実装する．
  #
  #  例:
  #  # model
  #  attr_accessible :name
  #  attr_accessible :name, :is_admin, :as => :admin
  #  
  #  # controller
  #  def assignment_scope
  #    current_user.admin? ? :admin : nil
  #  end
  #
  def assignment_scope
    nil
  end

  def new_resource
    self.resource = model.new
  end

  def assign_params
    resource.assign_attributes(params[model_key], :as => assignment_scope)
  end

  def find_resource
    self.resource = model.find(params[:id])
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

  def search_column?(model, column_name)
    return true if respond_to?("search_by_#{column_name}", true)
    column = model.columns_hash[column_name.to_s]
    column && [:string, :text, :integer].include?(column.type) || association_key?(column_name)
  end

  # JSON出力に利用するカラムリスト.
  # デフォルトではindexで表示する項目と同じ
  #
  def columns_for_json
    columns_for(:index)
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

  def set_defaults
    @title = t("crud.action_title." + crud_action.to_s, :name => model_name)
    self.columns = columns_for(crud_action)
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

  def render_json(resources)
    if resources.is_a?(Kaminari::PageScopeMethods)
      render json: {
        :data => resources,
        :total_pages => resources.total_pages,
        :current_page => resources.current_page
      }.to_json(:methods => :label)
    else
      render json: resources.to_json
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
    authorize_action
    new_resource
    do_action
  end

  def before_show
    find_resource
    do_action
    authorize_action
  end

  def before_new
    new_resource
    assign_params
    do_action
    authorize_action
  end

  def before_edit
    find_resource
    assign_params
    do_action
    authorize_action
  end

  def before_create
    new_resource
    authorize_action
    assign_params
  end

  def before_update
    find_resource
    authorize_action
    assign_params
  end

  def before_destroy
    find_resource
    authorize_action
    do_action
  end
end
