class Ar::MiscThrough < ApplicationRecord
  belongs_to :misc_belonging
  validates :name, presence: true
end
