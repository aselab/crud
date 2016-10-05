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

    def search_terms
      tokenize(params[:term])
    end

    def tokenize(word)
      word.to_s.strip.scan(/".*"|[^[[:space:]]]+/).map {|s|
        s.starts_with?('"') && s.ends_with?('"') ? s[1..-2] : s
      }
    end

    def sort_key?(key)
      respond_to?("sort_by_#{key}", true) || reflection.column_key?(key) ||
        (activerecord? && reflection.association_key?(key))
    end

    def query_params
      @query_params ||=
        if params[:op].blank?
          {}
        else
          h = {}
          op = params[:op].select{|k,v| (v == "!*") || query_value_present?(k) }.permit!.to_h
          op.each do |k,v|
            h[k] = {op: v, v: params[:v][k]}
          end
          h
        end
    end

    def query_value_present?(key)
      params[:v] && params[:v][key].is_a?(Array) && params[:v][key].any?(&:present?)
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
      association_columns = columns.select {|c| reflection.association_key?(c)}

      terms = search_terms
      model_columns = []
      conditions = []
      rejects = []
      columns_for_search.each do |c|
        _c = (c.to_s+"!").to_sym
        param = params[c] if params[c].present?
        _param = params[_c] if params[_c].present?
        cond = [c, param, model] if param
        reject = [c, _param, model] if _param
        if search_method_defined?(c)
          model_columns.push([model, c])
        elsif association = reflection.association_class(c)
          association_columns.push(c)
          fields = association.respond_to?(:search_field, true) ?
            association.send(:search_field) :
            [:name, :title].find {|c| reflection(association).column_key?(c)}
          Array(fields).each do |f|
            model_columns.push([association, f])
            cond = [f, param, association] if param
            reject = [f, _param, association] if _param
          end
        else
          model_columns.push([model, c])
        end
        conditions.push(search_condition_for_column(*cond)) if cond
        rejects.push(search_condition_for_column(*reject)) if reject
      end

      include_association(*association_columns)
      r = terms.inject(resources) do |scope, term|
        conds = model_columns.map do |model, column|
          search_condition_for_column(column, term, model)
        end.compact
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

      r=conditions.inject(r) do |scope, cond|
        scope.where(cond)
      end
      rejects.inject(r) do |scope, reject|
        scope.where.not(reject)
      end
    end

    def advanced_search_query
      @advanced_search_query ||= AdvancedSearchQuery
    end

    def do_advanced_search
      @query = advanced_search_query.build(model, columns_for_advanced_search, query_params)
      @query.apply(resources)
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
      ref = ModelReflection[model]
      method = "search_by_#{column}"
      if activerecord?
        cond = if respond_to?(method, true)
          c = send(method, term)
          case c
          when Array
            model.send(:sanitize_sql_for_conditions, c)
          when Hash
            # https://github.com/rails/rails/blob/4-2-stable/activerecord/lib/active_record/sanitization.rb#L89-L100
            attrs = model.send(:table_metadata).resolve_column_aliases(c)
            attrs = model.send(:expand_hash_conditions_for_aggregates, attrs)
            model.predicate_builder.build_from_hash(attrs.stringify_keys).map { |b|
              model.connection.visitor.compile b
            }.join(' AND ')
          else
            c
          end
        else
          c = ref.column_metadata(column)
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
          c = ref.column_metadata(column)
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
        column = if association = reflection.association_class(name)
          include_association(name)
          f = association.respond_to?(:sort_field, true) ?
            association.send(:sort_field) :
            [:name, :title, :id].find {|c| relection(association).column_key?(c)}
          "#{association.table_name}.#{f.to_s}" if f
        else
          c = reflection.column_metadata(name)
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
      if enable_advanced_search?
        @query ||= advanced_search_query.build(model, columns_for_advanced_search)
        self.resources = do_advanced_search || resources if query_params.present?
      else
        self.resources = do_search || resources
      end
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

    #
    # 詳細検索に利用するカラムリスト.
    #
    def columns_for_advanced_search
      columns_for(:index)
    end

    #
    # 詳細検索を使用するかどうか.
    # 今のところActiveRecordモデルのみ
    #
    def enable_advanced_search?
      activerecord?
    end

    def search_method_defined?(column_name)
      respond_to?("search_by_#{column_name}", true)
    end

    def search_column?(model, column_name)
      return true if search_method_defined?(column_name)
      type = reflection(model).column_type(column_name)
      (type && [:string, :text, :integer].include?(type)) ||
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