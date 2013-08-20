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
end
