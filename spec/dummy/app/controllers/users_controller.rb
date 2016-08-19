class UsersController < Crud::ApplicationController
  permit_keys :name, :birth_date, :company_id

  def columns_for_index
    [:name, :birth_date, :company]
  end

  def columns_for_show
    columns_for_index
  end

  def columns_for_create
    columns_for_index
  end

  def columns_for_update
    columns_for_index
  end

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
