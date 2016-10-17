class Ar::MiscBelonging < ApplicationRecord
  belongs_to :misc
  has_many :misc_throughs, dependent: :destroy

  validates :name, presence: true
end
