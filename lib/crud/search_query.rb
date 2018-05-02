module Crud
  class SearchQuery
    attr_reader :scope, :model, :reflection, :extensions

    def initialize(scope, *extensions)
      @scope = scope
      @model = scope.try(:model) || scope.try(:klass)
      @reflection = ModelReflection[@model]
      @extensions = extensions
    end

    def self.tokenize(keyword)
      keyword.to_s.strip.scan(/".*"|[^[[:space:]]]+/).map {|s|
        s.starts_with?('"') && s.ends_with?('"') ? s[1..-2] : s
      }
    end

    def include_associations(columns)
      associations = []
      storage_keys = []
      columns.each do |c|
        if reflection.association_key?(c)
          associations.push(c)
        elsif reflection.active_storage_key?(c)
          storage_keys.push(c)
        end
      end

      if storage_keys.present?
        @scope = storage_keys.inject(@scope) {|s, key| s.send("with_attached_#{key}")}
      end

      if associations.empty?
        @scope
      elsif reflection.activerecord?
        @scope = @scope.includes(associations).references(associations)
      elsif reflection.mongoid?
        @scope = @scope.includes(associations)
      end
    end

    def keyword_search(columns, keyword)
      include_associations(columns)

      terms = self.class.tokenize(keyword)
      @scope = terms.inject(@scope) do |scope, term|
        conds = columns.map do |column|
          where_clause(model, column, nil, term)
        end.compact
        cond = if conds.size > 1
          if reflection.activerecord?
            "(#{conds.join(" OR ")})"
          elsif reflection.mongoid?
            {"$and" => [{"$or" => conds}]}
          end
        else
          conds.first
        end
        scope.where(cond)
      end
    end

    def advanced_search(condition_values, operators)
      condition_values ||= {}
      operators ||= {}
      keys = (condition_values.keys + operators.keys).map(&:to_sym).uniq
      include_associations(keys)
      @scope = keys.inject(@scope) do |scope, column|
        operator = operators[column] || "equals"
        values = Array(condition_values[column])
        m = model
        key = column
        unless advanced_search_method_for(column)
          meta = reflection.column_metadata(column)
          case meta.try("[]", :type)
          when :belongs_to
            key = meta[:name]
          when :has_many, :has_and_belongs_to_many
            values = values.select(&:present?)
            if reflection.activerecord?
              m = meta[:class]
              key = :id
            elsif reflection.mongoid?
              foreign_key = reflection.association_reflection(column).foreign_key.to_sym
              if meta[:type] == :has_many
                key = :id
                values = meta[:class].in(id: values).pluck(foreign_key)
              else
                key = foreign_key
              end
            end
            values = [values]
          end
        end
        scope.where(where_clause(m, key, operator, *values))
      end
    end

    def sort(column, order)
      @scope = @scope.order(order_clause(column, order))
    end

    def where_clause(model, column, operator_name, *values)
      ref = ModelReflection[model]
      return nil if operator_name.try(:empty?)
      operator = operator_name ? Operator[operator_name] : DefaultOperator
      if operator_name.nil? && method = search_method_for(column)
        return ref.sanitize_sql(method.call(values.first))
      end

      if method = advanced_search_method_for(column)
        operator_name &&= Operator.canonical_name(operator_name)
        ref.sanitize_sql method.call(operator_name, *values)
      elsif operator
        operator.new(model, column).apply(*values)
      else
        ref.none_condition
      end
    end

    def order_clause(column, order)
      if method = sort_method_for(column)
        method.call(order)
      elsif reflection.activerecord?
        if association = reflection.association_class(column)
          ref = ModelReflection[association]
          f = association.respond_to?(:sort_field, true) ?
            association.send(:sort_field) :
            [:name, :title, :id].find {|c| ref.column_key?(c)}
          "#{association.table_name}.#{f} #{order}" if f
        elsif reflection.active_storage_key?(column)
          "active_storage_blobs.filename #{order}"
        else
          meta = reflection.column_metadata(column)
          "#{model.table_name}.#{meta[:name]} #{order}" if meta
        end
      elsif reflection.mongoid?
        { column => order }
      end
    end

    def search_column?(name)
      search_method_for(name) || advanced_search_method_for(name) || reflection.searchable?(name)
    end

    def advanced_search_column?(name)
      !!(advanced_search_method_for(name) || reflection.column_metadata(name))
    end

    def sort_column?(name)
      sort_method_for(name) || reflection.sortable?(name)
    end

    private
    def extension_method(name)
      extensions.find {|e| e.respond_to?(name, true)}.try(:method, name)
    end

    def search_method_for(column)
      extension_method("search_by_#{column}")
    end

    def advanced_search_method_for(column)
      extension_method("advanced_search_by_#{column}")
    end

    def sort_method_for(column)
      extension_method("sort_by_#{column}")
    end
  end
end

require "crud/search_query/operator"
