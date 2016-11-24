class Ar::MiscThrough < ApplicationRecord
  belongs_to :misc_belonging
  has_one :misc, through: :misc_belonging
  validates :name, presence: true
end
