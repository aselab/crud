# coding: utf-8
require 'spec_helper'

describe Crud::ApplicationController do
  def stub_params(params = nil)
    controller.stub!(:params).and_return(params || {})
  end

  describe "#tokenize" do
    it "nilを指定した場合" do
      expect(controller.send(:tokenize, nil)).to match_array []
    end

    it "空文字を指定した場合" do
      expect(controller.send(:tokenize, "")).to match_array []
    end

    it "スペースを含まない文字を指定した場合" do
      expect(controller.send(:tokenize, "キーワード1")).to match_array ["キーワード1"]
    end

    it "スペース区切りで分割されること" do
      expect(controller.send(:tokenize, " キーワード1 キーワード2　 キーワード3　")).to match_array ["キーワード1", "キーワード2", "キーワード3"]
    end

    it "ダブルクォートでスペースを含むキーワードを指定できること" do
      expect(controller.send(:tokenize, 'abc "スペース含む キーワード" def')).to match_array ["abc", "スペース含む キーワード", "def"]
    end

    it "正しくダブルクォートが閉じられていない場合文字として扱うこと" do
      expect(controller.send(:tokenize, 'key"word "pre')).to match_array ['key"word', '"pre']
    end
  end

  describe "#search_sql_for_column" do
    it "search_by_column メソッドが定義されていたらそれを呼び出すこと" do
      sql = ["test = ?", "name1"]
      expect(controller).to receive(:search_by_name).with("name1").and_return(sql)
      user = double("user model")
      expect(user).to receive(:table_name).and_return("users")
      expect(user).to receive(:sanitize_sql_for_conditions).with(sql, "users").and_return("sanitized sql")
      expect(controller.send(:search_sql_for_column, user, "name", "name1")).to eq "sanitized sql"
        "test = 'name1'"
    end
  end
end
