class Ar::User < ApplicationRecord
  has_many :permissions, dependent: :destroy
  validates :first_name, :last_name, presence: true

  def name
    "#{last_name} #{first_name}"
  end

  def age
    return nil unless birth_date
    t1 = Date.today.strftime("%Y%m%d").to_i
    t2 = birth_date.strftime("%Y%m%d").to_i
    (t1 - t2) / 10000
  end

  def self.advanced_search_by_name(operator, value)
    operator ||= "contains"
    case operator
    when "equals"
      last, first = value.to_s.split(" ")
      { last_name: last, first_name: first}
    when "contains"
      ["last_name LIKE :value OR first_name LIKE :value", value: "%#{value}%"]
    else
      "0 = 1"
    end
  end

  def self.search_by_age(term)
    age = Integer(term)
    advanced_search_by_age("equals", age)
  rescue
  end

  def self.advanced_search_by_age(operator, *values)
    v1, v2 = values.map {|v| Integer(v)}
    case operator
    when "equals"
      {birth_date: ((v1 + 1).years.ago + 1.day).to_date..(v1.years.ago).to_date}
    when "between"
      {birth_date: ((v2 + 1).years.ago + 1.day).to_date..(v1.years.ago + 1.day).to_date}
    else
      "0 = 1"
    end
  rescue
    "0 = 1"
  end
end
