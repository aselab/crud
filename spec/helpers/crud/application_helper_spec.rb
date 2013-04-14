# coding: utf-8
require 'spec_helper'

describe Crud::ApplicationHelper do
  describe "#sort_link_to" do
    before do
      @params = {:controller => "foo", :action => "bar",
        :sort_key => "sort_key", :sort_order => "asc"}
      helper.stub!(:params).and_return(@params)

      model = Object.new
      model.define_singleton_method(:human_attribute_name) {|key|
        "human name of #{key.to_s}"
      }
      helper.stub!(:model).and_return(model)
      helper.stub!(:column_key?).and_return(false)
      helper.stub!(:association_key?).and_return(false)
    end

    context "DBに存在するカラムの場合" do
      before do
        helper.stub!(:column_key?).and_return(true)
      end

      it "sort_keyと一致しない場合のリンクが正しいこと" do
        helper.should_receive(:link_to).with("human name of aaa", 
          @params.dup.update(:sort_key => "aaa", :sort_order => "asc"),
          :class => nil).and_return("xxx")
        helper.sort_link_to(:aaa).should == "xxx"
      end

      it "sort_keyと一致した場合のリンクが正しいこと" do
        helper.should_receive(:link_to).with("human name of sort_key", 
          @params.dup.update(:sort_key => "sort_key", :sort_order => "desc"),
          :class => "asc").and_return("xxx")
        helper.sort_link_to(:sort_key).should == "xxx"
      end
    end

    context "関連の場合" do
      before do
        helper.stub!(:association_key?).and_return(true)
      end

      it "sort_keyと一致しない場合のリンクが正しいこと" do
        helper.should_receive(:link_to).with("human name of aaa", 
          @params.dup.update(:sort_key => "aaa", :sort_order => "asc"),
          :class => nil).and_return("xxx")
        helper.sort_link_to(:aaa).should == "xxx"
      end

      it "sort_keyと一致した場合のリンクが正しいこと" do
        helper.should_receive(:link_to).with("human name of sort_key", 
          @params.dup.update(:sort_key => "sort_key", :sort_order => "desc"),
          :class => "asc").and_return("xxx")
        helper.sort_link_to(:sort_key).should == "xxx"
      end
    end

    it "DBカラムまたは関連でない場合はラベルを返すこと" do
      helper.sort_link_to(:aaa).should == "human name of aaa"
    end
  end

  describe "#to_label" do
    it "nilまたは空文字のとき第2引数の値を返すこと" do
      helper.to_label(nil).should == nil
      helper.to_label("").should == nil
      helper.to_label(nil, "aaa").should == "aaa"
      helper.to_label("", "bbb").should == "bbb"
    end

    it "日付や時刻のときI18n.lした結果を返すこと" do
      date = Date.new(2000, 3, 4)
      time = Time.new(2000, 3, 4, 5, 6, 7)
      I18n.should_receive(:l).with(date).and_return("xxx")
      helper.to_label(date).should == "xxx"
      I18n.should_receive(:l).with(time).and_return("yyy")
      helper.to_label(time).should == "yyy"
    end

    it "Enumerableのとき各要素をto_labelした結果を返すこと" do
      helper.to_label([nil, 1, Date.new(2001, 2, 3), "xxx"], "aaa").should ==
        ["aaa", "1", "2001-02-03", "xxx"]
    end

    it "#label, #text, #name, #to_s の優先順で結果を返すこと" do
      o = Object.new
      o.should_receive(:to_s).and_return("to_s")
      helper.to_label(o).should == "to_s"
      o.should_receive(:name).and_return("name")
      helper.to_label(o).should == "name"
      o.should_receive(:text).and_return("text")
      helper.to_label(o).should == "text"
      o.should_receive(:label).and_return("label")
      helper.to_label(o).should == "label"
    end
  end
end
