module Crud
  class SearchQuery
    attr_reader :scope, :columns, :model, :reflection, :extension

    def initialize(scope, search_columns, extension = nil)
      @scope = scope
      @columns = search_columns
      @model = scope.model
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

    def search_method_for(column)
      extension_method("search_by_#{column}")
    end

    def sort_method_for(column)
      extension_method("sort_by_#{column}")
    end

    def condition_by_method(method, value, operator)
      cond = case method.arity
      when 1
        operator.nil? ? method.call(value) : none
      when 2
        method.call(value, operator)
      else
        raise "#{method} has invalid arguments"
      end
    end

    def where_clause(model, column, value, operator = nil)
      ref = ModelReflection[model]

      condition = if method = search_method_for(column)
        cond = condition_by_method(method, value, operator)
        ref.activerecord? ? ref.sanitize_sql(cond) : cond
      elsif ref.activerecord?
        meta = ref.column_metadata(column)
        return none unless meta
        name = meta[:name]
        t = model.arel_table
        case meta[:type]
        when :enum
          enum_values = ref.enum_values_for(column)
          t[name].eq(enum_values[value] || value)
        when :string, :text
          t[name].matches("%#{value}%")
        when :integer
          t[name].eq(Integer(value)) rescue none
        else
          t[name].eq(value)
        end
      elsif reflection.mongoid?
      end
      condition.respond_to?(:to_sql) ? condition.to_sql : condition
    end

    private
    def extension_method(name)
      extension.try(:respond_to?, name, true) ? extension.method(name) : nil
    end

    def none
      if reflection.activerecord?
        "0 = 1"
      elsif reflection.mongoid?
        { id: 0 }
      end
    end
  end
end
