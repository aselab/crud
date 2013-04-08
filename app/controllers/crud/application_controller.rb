class Crud::ApplicationController < ApplicationController
  helper_method :model, :resources, :resource, :columns,
    :stored_params, :column_key?, :association_key?

  before_filter :new_resource, :only => [:new, :create]
  before_filter :find_resource, :only => [:show, :edit, :update, :destroy]
  before_filter :set_defaults

  def index
    authorize! :index, model
    do_index
    respond_to do |format|
      format.html # index.html.erb
      format.json { render_json resources }
    end
  end

  def show
    do_show
    authorize! :read, resource
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: resource }
    end
  end

  def new
    do_new
    authorize! :create, resource
    respond_to do |format|
      format.html { render action: "edit" }
      format.json { render json: resource }
    end
  end

  def edit
    do_edit
    authorize! :update, resource
  end

  def create
    assign_params
    authorize! :create, resource
    respond_to do |format|
      if do_create
        format.html { redirect_after_success notice: t("message.successfully_created", :name => model_name) }
        format.json { render json: resource, status: :created, location: resource }
      else
        format.html { render action: "edit" }
        format.json { render json: resource.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    assign_params
    authorize! :update, resource
    respond_to do |format|
      if do_update
        format.html { redirect_after_success notice: t("message.successfully_updated", :name => model_name) }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: resource.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    authorize! :destroy, resource
    do_destroy
    respond_to do |format|
      format.html { redirect_after_success notice: t("message.successfully_deleted", :name => model_name) }
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

  def search_query(columns, terms)
    return nil if columns.empty? || terms.empty?

    terms.map {|term|
      "(" + columns.map {|column|
        ActiveRecord::Base.send(:sanitize_sql_array,
          ["#{column} like ?", "%#{term}%"])
      }.join(" or ") + ")"
    }.join(" and ")
  end

  #
  # indexアクションで呼び出される内部メソッド.
  # オーバーライドしてself.resourcesに表示対象を格納するように実装する．
  #
  def do_search
    format = (params[:format] || :html).to_sym
    columns = format == :html ? columns_for(:index) : columns_for(format)
    associations, columns = columns.partition(&:association_key?)
    all_columns_exist = columns.all?(&:column_key?)

    self.resources = (associations.empty? && all_columns_exist) ?
        model.select([:id] + columns).accessible_by(current_ability) :
        model.includes(associations).accessible_by(current_ability)

    search_by_sql
  end

  def do_filter
    if ids = params[:except_ids]
      self.resources = resources.where(["#{model.table_name}.id not in (?)", ids])
    end
  end

  def search_by_sql
    terms = search_terms

    columns = columns_for_search.map {|c|
      reflection = model.reflections[c.to_sym]
      if reflection
        self.resources = resources.includes(c.to_sym)
        association = reflection.class_name.constantize
        f = association.respond_to?(:search_field) ?
          association.send(:search_field) :
          [:name, :title].find {|c| association.columns_hash.has_key?(c.to_s)}
        "#{association.table_name}.#{f.to_s}"
      else
        "#{model.table_name}.#{model.columns_hash[c.to_s].name}"
      end
    }
    self.resources = resources.where(search_query(columns, terms))
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
  # showメソッドで呼び出される内部メソッド.
  # 表示対象はresource
  #
  def do_show
  end

  #
  # newメソッドで呼び出される内部メソッド.
  # 表示対象はresource
  #
  def do_new
  end

  #
  # editメソッドで呼び出される内部メソッド.
  # 表示対象はresource
  #
  def do_edit
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
  # デフォルトではindexで表示する項目のうちtypeがstringであるものまたは関連
  #
  def columns_for_search
    columns_for(:index).select {|c|
      column = model.columns_hash[c.to_s]
      column && column.type == :string || association_key?(c)
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
    params.dup.extract!(keys).merge(overwrites)
  end

  def set_defaults
    action = params[:action].to_sym
    action = :create if action == :new
    action = :update if action == :edit
    @title = t("action_title." + action.to_s, :name => model_name)
    self.columns = columns_for(action)
  end

  def set_redirect_to(url)
    @redirect_to_url = url
  end

  # 作成，更新，削除成功後のリダイレクト先
  def redirect_after_success(options)
    redirect_to(@redirect_to_url || stored_params(:action => :index), options)
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
end
