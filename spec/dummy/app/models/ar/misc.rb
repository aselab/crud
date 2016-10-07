class Ar::Misc < ApplicationRecord
  extend Enumerize
  has_many :misc_belongings
  enumerize :enumerized, in: [:A, :B, :C]
end
