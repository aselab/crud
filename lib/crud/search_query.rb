module Crud
  class SearchQuery
    attr_reader :scope, :columns, :model, :reflection, :extension

    def initialize(scope, search_columns, extension = nil)
      @scope = scope
      @columns = search_columns
      @model = scope.try(:model) || scope.try(:klass)
      @reflection = ModelReflection[@model]
      @extension = extension
      include_associations
    end

    def self.tokenize(keyword)
      keyword.to_s.strip.scan(/".*"|[^[[:space:]]]+/).map {|s|
        s.starts_with?('"') && s.ends_with?('"') ? s[1..-2] : s
      }
    end

    def include_associations
      associations = columns.select {|c| reflection.association_key?(c)}
      if associations.empty?
        @scope
      elsif reflection.activerecord?
        @scope = @scope.includes(associations).references(associations)
      elsif reflection.mongoid?
        @scope = @scope.includes(associations)
      end
    end

    def keyword_search(keyword)
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
      @scope = keys.inject(@scope) do |scope, column|
        operator = operators[column] || "equals"
        values = Array(condition_values[column])
        meta = reflection.column_metadata(column)
        m = model
        key = column
        case meta[:type]
        when :belongs_to
          key = meta[:name]
        when :has_many, :has_and_belongs_to_many
          m = meta[:class]
          values = [values.select(&:present?)]
          key = :id
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
        else
          meta = reflection.column_metadata(column)
          "#{model.table_name}.#{meta[:name]} #{order}" if meta
        end
      elsif reflection.mongoid?
        { column => order }
      end
    end

    private
    def extension_method(name)
      extension.try(:respond_to?, name, true) ? extension.method(name) : nil
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
