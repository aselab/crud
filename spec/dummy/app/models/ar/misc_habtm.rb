class Ar::MiscHabtm < ApplicationRecord
  has_and_belongs_to_many :miscs
  validates :name, presence: true
end
