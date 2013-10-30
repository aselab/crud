# coding: utf-8
require 'spec_helper'

describe Crud::ApplicationHelper do
  describe "#link_to_sort" do
    before do
      @params = {:controller => "foo", :action => "bar",
        :sort_key => "sort_key", :sort_order => "asc"}
      helper.stub(:params).and_return(@params)
      helper.stub(:sort_key).and_return(:sort_key)
      helper.stub(:sort_order).and_return(:asc)

      model = Object.new
      model.define_singleton_method(:human_attribute_name) {|key|
        "human name of #{key.to_s}"
      }
      helper.stub(:model).and_return(model)
      helper.stub(:sort_key?).and_return(false)
    end

    context "ソートできるカラムの場合" do
      before do
        helper.stub(:sort_key?).and_return(true)
      end

      it "sort_keyと一致しない場合のリンクが正しいこと" do
        helper.should_receive(:link_to).with("human name of aaa", 
          @params.dup.update(:sort_key => "aaa", :sort_order => "asc"),
          :class => nil).and_return("xxx")
        helper.link_to_sort(:aaa).should == "xxx"
      end

      it "sort_keyと一致した場合のリンクが正しいこと" do
        helper.should_receive(:link_to).with("human name of sort_key", 
          @params.dup.update(:sort_key => "sort_key", :sort_order => "desc"),
          :class => "asc").and_return("xxx")
        helper.link_to_sort(:sort_key).should == "xxx"
      end
    end

    it "ソートできない場合はラベルを返すこと" do
      helper.link_to_sort(:aaa).should == "human name of aaa"
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

  describe "#column_html" do
    before do
      @resource = double("resource", :aaa => "xxx")
      helper.stub(:params).and_return({:controller => "controller_name"})
    end

    subject { helper.column_html(@resource, :aaa) }

    it "引数がnilのときnilを返すこと" do
      helper.column_html(nil, nil).should == nil
      helper.column_html(nil, :aaa).should == nil
      helper.column_html(@resource, nil).should == nil
    end

    context '#{controller_name}_#{column_name}_htmlという名前のhelperメソッドが定義されているとき' do
      before { helper.should_receive(:controller_name_aaa_html).with(@resource, "xxx").and_return("html") }
      it("その結果を返すこと") { should == "html" }
    end

    context '#{column_name}_htmlという名前のhelperメソッドが定義されているとき' do
      before { helper.should_receive(:aaa_html).with(@resource, "xxx").and_return("short_html") }
      it("その結果を返すこと") { should == "short_html" }
    end

    context '#{column_name}_labelという名前のmodelメソッドが定義されているとき' do
      it "その結果を返すこと" do
        @resource.should_receive(:aaa_label).and_return("label")
        should == "label"
      end

      it "エスケープされること" do
        @resource.should_receive(:aaa_label).and_return("<label>")
        should == "&lt;label&gt;"
      end
    end

    context "どのメソッドも定義されていないとき" do
      it "to_labelメソッドの結果をsimple_formatして返すこと" do
        helper.should_receive(:to_label).with(@resource.aaa).and_return("to_label")
        helper.should_receive(:simple_format).with("to_label").and_return("simple_format")
        should == "simple_format"
      end

      it "エスケープされること" do
        helper.should_receive(:to_label).with(@resource.aaa).and_return("<to_label>")
        helper.should_receive(:simple_format).with("&lt;to_label&gt;").and_return("simple_format")
        should == "simple_format" 
      end
    end
  end
end
