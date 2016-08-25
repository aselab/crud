class AdvancedSearchQuery
  include ActiveModel::Model
  include ActiveModel::Validations::Callbacks

  OPERATORS = {
    "==" => {label: "equals", args: 1},
    "!=" => {label: "not_equals", args: 1},
    "<>" => {label: "between", args: 2},
    "<=" => {label: "greater_or_equal", args: 1},
    ">=" => {label: "less_or_equal", args: 1},
    "~"  => {label: "contains", args: 1},
    "!~" => {label: "not_contains", args: 1},
    "!*" => {label: "none", args: 0}
  }.freeze

  attr_accessor :crud, :columns, :conditions, :query_params

  def initialize(crud, columns, conditions, query_params)
    @crud = crud
    @columns = columns
    @conditions = conditions
    @query_params = query_params
  end

  def self.build(crud, model, columns, query_params = {})
    conditions = []
    columns.each do |column|
      r = model.reflections[column.to_s]
      arel_column = r.try(:belongs_to?) ? r.foreign_key : column
      arel = model.arel_table[arel_column.to_sym]
      query_param = query_params[column.to_s]
      next if query_param.blank?
      operator = query_param[:op]
      values = query_param[:v]
      conditions << build_condition(arel, operator, values)
    end
    self.new(crud, columns, conditions, query_params)
  end

  def self.build_condition(arel, operator, values)
    case operator
    when "=="
      arel.eq(values[0])
    when "!="
      arel.not_eq(values[0])
    when "<>"
      arel.between(values[0]..values[1])
    when "<="
      arel.gteq(values[0])
    when ">="
      arel.lteq(values[0])
    when "~"
      arel.matches("%#{values[0]}%")
    when "!~"
      arel.matches("%#{values[0]}%").not
    when "!*"
      arel.eq(nil)
    end
  end

  def apply(resources)
    r = resources
    self.conditions.each {|c| r = r.where(c) }
    r
  end

  def query_param(column)
    self.query_params[column.to_s]
  end

  def operator(column)
    query_param(column).try("[]", :op)
  end

  def value(column)
    query_param(column).try("[]", :v) || []
  end

  def operator_label(operator)
    label_key = OPERATORS[operator].try("[]", :label)
    I18n.t("helpers.query.#{label_key}") if label_key
  end

  def operator_args
    @operator_args ||= OPERATORS.map{|k,v| [k, v[:args]]}.to_h
  end

  def operators_by_column(column)
    case crud.send(:column_type, column)
    when :integer
      ["==", "!=", "<=", ">=","<>", "!*"]
    when :string, :text
      ["==", "!=", "~", "!~", "!*"]
    when :date, :time, :datetime
      ["<>", "==", "!=", "<=", ">=", "!*"]
    else
      ["==", "!=", "!*"]
    end
  end

  def operators_selector(column)
    (operators_by_column(column) || []).map do |operator|
      [operator_label(operator), operator]
    end
  end

  def dom_id
    "advanced-search-#{object_id}"
  end

  def empty?
    conditions.blank?
  end
end
