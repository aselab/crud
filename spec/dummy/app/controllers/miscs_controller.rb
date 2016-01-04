class MiscsController < Crud::ApplicationController
  permit_keys :boolean, :string, :email, :url, :phone, :password, :integer, :datetime, :date, :time, :time_zone
end
