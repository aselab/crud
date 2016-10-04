class Ar::Permission < ApplicationRecord
  belongs_to :user
  belongs_to :permissible, polymorphic: true
end
