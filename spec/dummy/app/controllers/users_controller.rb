class UsersController < Crud::ApplicationController
  permit_keys :name, :birth_date

  protected
  def create?(resource)
    User.count < 5
  end

  def update?(resource)
    resource != User.first
  end
end
