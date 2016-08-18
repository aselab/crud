# coding: utf-8
require 'spec_helper'

describe UsersController do
  describe "respond_toブロックの挙動のオーバーライド" do
    it "htmlフォーマット" do
      post :create, params: { user: {name: "test"} }
      expect(flash[:notice]).to eq "htmlフォーマットの作成成功時の動作をオーバーライド"
    end

    it "jsフォーマット" do
      post :create, params: { user: {name: "test"}, format: :js }
      expect(flash[:notice]).to eq "User was successfully created."
    end
  end
end
