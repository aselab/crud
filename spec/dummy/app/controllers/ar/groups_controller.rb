class Ar::GroupsController < Crud::ApplicationController
  permit_keys :name, permissions_attributes: [:_destroy, :id, :user_id, :flags]

  protected
  # 表示/更新対象のカラムリスト
  def model_columns
    [:name, :permissions]
  end

  # 一覧表示のカラムリスト
  def columns_for_index
    [:name]
  end

  def do_create
    if resource.save
      resource.permissions.add(current_user, :manage) unless current_user.is_admin || resource.authorized?(current_user, :manage)
      true
    else
      false
    end
  end

  class Authorization < Crud::Authorization::Default
    def show?(group)
      admin? || group.authorized?(current_user, :read)
    end

    def create?(group)
      current_user
    end

    def manage?(group)
      admin? || group.authorized?(current_user, :manage)
    end

    private
    def admin?
      current_user.try(:is_admin)
    end
  end
end
