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

  describe "#order_by" do
    before do
      @model = mock_model("TestModel")
      @model.stub!(:table_name).and_return("t")
      @model.stub!(:reflections).and_return({})
      controller.stub!(:model).and_return(@model)
    end

    it "sort_keyを指定していない場合" do
      stub_params
      controller.send(:order_by).should == nil
      stub_params(:sort_order => "asc")
      controller.send(:order_by).should == nil
    end

    it "sort_keyだけ指定している場合" do
      stub_params(:sort_key => "abc")
      controller.send(:order_by).should == "t.abc"
    end

    it "sort_keyとsort_orderを指定した場合" do
      stub_params(:sort_key => "abc", :sort_order => "asc")
      controller.send(:order_by).should == "t.abc asc"
    end
  end
end
