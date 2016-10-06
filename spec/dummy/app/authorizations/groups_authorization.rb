class GroupsAuthorization < Crud::Authorization::Default
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
