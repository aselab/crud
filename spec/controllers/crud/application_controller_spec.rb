# coding: utf-8
require 'spec_helper'

describe Crud::ApplicationController do
  def stub_params(params = nil)
    controller.stub!(:params).and_return(params || {})
  end

  describe "#tokenize" do
    it "nilを指定した場合" do
      controller.send(:tokenize, nil).should == []
    end

    it "空文字を指定した場合" do
      controller.send(:tokenize, "").should == []
    end

    it "スペースを含まない文字を指定した場合" do
      controller.send(:tokenize, "キーワード1").should == ["キーワード1"]
    end

    it "スペース区切りで分割されること" do
      controller.send(:tokenize, " キーワード1 キーワード2　 キーワード3　").should == ["キーワード1", "キーワード2", "キーワード3"]
    end

    it "ダブルクォートでスペースを含むキーワードを指定できること" do
      controller.send(:tokenize, 'abc "スペース含む キーワード" def').should == ["abc", "スペース含む キーワード", "def"]
    end

    it "正しくダブルクォートが閉じられていない場合文字として扱うこと" do
      controller.send(:tokenize, 'key"word "pre').should == ['key"word', '"pre']
    end
  end

  describe "#do_search_by_column" do
    it "search_by_column メソッドが定義されていたらそれを呼び出すこと" do
      sql = ["test = ?", "name1"]
      expect(controller).to receive(:search_by_name).with("name1").and_return(sql)
      user = double("user model")
      expect(user).to receive(:sanitize_sql_array).with(sql).and_return("sanitized sql")
      controller.send(:do_search_by_column, user, "name", "name1").should == "sanitized sql"
        "test = 'name1'"
    end
  end
end
