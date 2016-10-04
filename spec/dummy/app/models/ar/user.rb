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
end
