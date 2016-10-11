module Crud
  class SearchQuery
    attr_reader :scope, :columns, :model, :reflection, :extension

    def initialize(scope, search_columns, extension = nil)
      @scope = scope
      @columns = search_columns
      @model = scope.try(:model) || scope.try(:klass)
      @reflection = ModelReflection[@model]
      @extension = extension
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
      include_associations

      terms = self.class.tokenize(keyword)
      columns.each do |c|
      end
    end

    def where_clause(model, column, operator, *values)
      ref = ModelReflection[model]

      if operator.blank?
        if method = search_method_for(column)
          return ref.sanitize_sql(method.call(values.first))
        end
        operator = case ref.column_type(column)
        when :string, :text
          "contains"
        else
          "equals"
        end
      end

      cond = if method = advanced_search_method_for(column)
        method.call(Operator.canonical_name(operator), *values)
      elsif op = Operator[operator]
        op.new(model, column).apply(*values)
      else
        ref.none_condition
      end
      ref.sanitize_sql(cond)
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
