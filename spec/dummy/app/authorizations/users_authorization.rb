class UsersAuthorization < Crud::Authorization::Default
  def manage?(user)
    current_user.try(:is_admin) || user == current_user
  end

  def destroy?(user)
    manage?(user) && user != current_user
  end
end
