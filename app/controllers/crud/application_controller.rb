class Crud::ApplicationController < ApplicationController
  helper Crud::BootstrapHelper
  helper_method :model, :model_name, :resources, :resource, :columns,
    :stored_params, :column_key?, :association_key?

  before_filter :new_resource, :only => [:index, :new, :create]
  before_filter :find_resource, :only => [:show, :edit, :update, :destroy]
  before_filter :set_defaults

  before_filter :assign_params, :only => [:create, :update]
  before_filter :authorize_before_action, :except => [:show, :new, :edit]
  before_filter :do_action, :except => [:create, :update]
  before_filter :authorize_after_action, :only => [:show, :new, :edit]

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
      format.html { render action: "edit" }
      format.json { render json: resource }
    end
  end

  def edit
  end

  def create
    respond_to do |format|
      if do_create
        format.html { redirect_after_success notice: message(:successfully_created, :name => model_name) }
        format.json { render json: resource, status: :created, location: resource }
      else
        format.html { render action: "edit" }
        format.json { render json: resource.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if do_update
        format.html { redirect_after_success notice: message(:successfully_updated, :name => model_name) }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
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
    @model_key ||= model.model_name.underscore.to_sym
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

  #
  #=== 権限チェック
  #
  # デフォルトでは authorize! :action, resource でチェックする。
  # authorize_:actionという名前のメソッドを定義すると、
  # アクションごとの権限チェック処理をオーバーライドできる。
  #
  def authorize_action
    method = "authorize_" + crud_action.to_s
    if respond_to?(method)
      send(method)
    else
      authorize! crud_action, resource
    end
  end

  def authorize_before_action
    authorize_action
  end

  def authorize_after_action
    authorize_action
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
    send(method) if respond_to?(method)
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
        model.select([:id] + columns).accessible_by(current_ability, :read) :
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
        fields = association.respond_to?(:search_field) ?
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
        c = model.columns_hash[column.to_s]
        column_name = "#{model.table_name}.#{c.name}"
        case c.type
        when :string, :text
          model.send(:sanitize_sql_array, ["#{column_name} like ?", "%#{term}%"])
        when :integer
          model.send(:sanitize_sql_hash, column_name => Integer(term)) rescue nil
        end
      }.compact
      conds.size > 1 ? "(#{conds.join(" OR ")})" : conds.first
    }.compact.join(" AND ")
  end

  #
  # order句
  #
  def order_by
    if params.has_key?(:sort_key)
      key = params[:sort_key]
      reflection = model.reflections[key.to_sym]
      key = if reflection
        self.resources = resources.includes(key.to_sym)
        association = reflection.class_name.constantize
        f = association.respond_to?(:sort_field) ?
          association.send(:sort_field) :
          [:name, :title, :id].find {|c| association.columns_hash.has_key?(c.to_s)}
        "#{association.table_name}.#{f.to_s}"
      else
        "#{model.table_name}.#{key}"
      end

      [key, params[:sort_order]].compact.join(" ")
    end
  end

  def do_sort
    order = order_by
    self.resources = resources.order(order) if order
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
    self.respond_to?(column_method) ?  self.send(column_method) : model_columns
  end

  #
  # 検索に利用するカラムリスト.
  # デフォルトではindexで表示する項目のうちtypeがstring, text, integerであるものまたは関連
  #
  def columns_for_search
    columns_for(:index).select {|c|
      column = model.columns_hash[c.to_s]
      column && [:string, :text, :integer].include?(column.type) || association_key?(c)
    }
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

  unless method_defined?(:current_user)
    define_method(:current_user) {}
  end
end
