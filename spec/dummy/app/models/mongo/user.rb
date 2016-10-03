class Mongo::User
  include Mongoid::Document
  field :first_name, type: String
  field :last_name, type: String
  field :email, type: String
  field :birth_date, type: Date

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
end
