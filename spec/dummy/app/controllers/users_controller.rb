class UsersController < Crud::ApplicationController
  permit_keys :name, :birth_date

  def create
    super do |format|
      format.html { redirect_after_success notice: "htmlフォーマットの作成成功時の動作をオーバーライド" }
    end
  end

  protected
  class Authorization < Crud::Authorization::Default
    def create?(resource)
      User.count < 5
    end

    def update?(resource)
      resource != User.first
    end
  end
end
