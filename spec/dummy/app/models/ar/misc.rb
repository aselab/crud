class Ar::Misc < ApplicationRecord
  extend Enumerize
  has_many :misc_belongings, dependent: :destroy
  has_many :misc_throughs, through: :misc_belongings
  has_and_belongs_to_many :misc_habtms
  has_one_attached :file

  enumerize :enumerized, in: [:A, :B, :C]

  def self.search_field
    :string
  end
end
