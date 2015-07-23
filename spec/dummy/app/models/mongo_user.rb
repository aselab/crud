class MongoUser
  include Mongoid::Document

  belongs_to :mongo_group

  field :name, type: String
  field :birth_date, type: Date

  field :array, type: Array
  field :number, type: Integer

  def age
    return nil unless birth_date
    t1 = Date.today.strftime("%Y%m%d").to_i
    t2 = birth_date.strftime("%Y%m%d").to_i
    (t1 - t2) / 10000
  end
end
