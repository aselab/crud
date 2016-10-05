class Ar::MiscBelonging < ApplicationRecord
  belongs_to :misc

  validates :name, presence: true
end
