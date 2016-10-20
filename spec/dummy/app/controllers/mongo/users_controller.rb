class Mongo::UsersController < UsersController
  protected
  def advanced_search_by_name(operator, value)
    operator ||= "contains"
    case operator
    when "equals"
      last, first = value.to_s.split(" ")
      { last_name: last, first_name: first}
    when "contains"
      value = Regexp.new(Regexp.escape(value))
      { "$or" => [{last_name: value}, {first_name: value}] }
    else
      { id: 0 }
    end
  end

  def search_by_age(term)
    age = Integer(term)
    advanced_search_by_age("equals", age)
  rescue
  end

  def advanced_search_by_age(operator, *values)
    v1, v2 = values.map {|v| Integer(v)}
    case operator
    when "equals"
      {birth_date: ((v1 + 1).years.ago + 1.day).to_date..(v1.years.ago).to_date}
    when "between"
      {birth_date: ((v2 + 1).years.ago + 1.day).to_date..(v1.years.ago + 1.day).to_date}
    else
      { id: 0 }
    end
  rescue
    { id: 0 }
  end
end
