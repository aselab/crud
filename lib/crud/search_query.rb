module Crud
  class SearchQuery
    attr_reader :scope, :columns, :reflection, :extension

    def initialize(scope, search_columns, extension = nil)
      @scope = scope
      @columns = search_columns
      @reflection = ModelReflection[scope.model]
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
  end
end
