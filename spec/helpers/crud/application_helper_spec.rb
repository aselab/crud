# coding: utf-8
require 'spec_helper'

describe Crud::ApplicationHelper do
  describe "#link_to_sort" do
    before do
      params = {:controller => "foo", :action => "bar",
        :sort_key => "sort_key", :sort_order => "asc"}
      @params = ActionController::Parameters.new(params)
      allow(helper).to receive(:params).and_return(@params)
      allow(helper).to receive(:sort_key).and_return(:sort_key)
      allow(helper).to receive(:sort_order).and_return(:asc)

      model = Object.new
      model.define_singleton_method(:human_attribute_name) {|key|
        "human name of #{key.to_s}"
      }
      allow(helper).to receive(:model).and_return(model)
      allow(helper).to receive(:sort_key?).and_return(false)
    end

    context "ソートできるカラムの場合" do
      before do
        allow(helper).to receive(:sort_key?).and_return(true)
      end

      it "sort_keyと一致しない場合のリンクが正しいこと" do
        expect(helper).to receive(:link_to).with("human name of aaa", 
          @params.to_unsafe_hash.merge(:sort_key => "aaa", :sort_order => "asc"),
          remote: nil
          ).and_return("xxx")
        expect(helper.link_to_sort(:aaa)).to eq 'xxx<i class="fas fa-sort text-muted"></i>'
      end

      it "sort_keyと一致した場合のリンクが正しいこと" do
        expect(helper).to receive(:link_to).with("human name of sort_key", 
          @params.to_unsafe_hash.merge(:sort_key => "sort_key", :sort_order => "desc"),
          remote: nil
          ).and_return("xxx")
        expect(helper.link_to_sort(:sort_key)).to eq 'xxx<i class="fas fa-sort-up"></i>'
      end
    end

    it "ソートできない場合はラベルを返すこと" do
      expect(helper.link_to_sort(:aaa)).to eq "human name of aaa"
    end
  end

  describe "#to_label" do
    it "nilまたは空文字のとき第2引数の値を返すこと" do
      expect(helper.to_label(nil)).to be nil
      expect(helper.to_label("")).to be nil
      expect(helper.to_label(nil, "aaa")).to eq "aaa"
      expect(helper.to_label("", "bbb")).to eq "bbb"
    end

    it "日付や時刻のときI18n.lした結果を返すこと" do
      date = Date.new(2000, 3, 4)
      time = Time.new(2000, 3, 4, 5, 6, 7)
      expect(I18n).to receive(:l).with(date).and_return("xxx")
      expect(helper.to_label(date)).to eq "xxx"
      expect(I18n).to receive(:l).with(time).and_return("yyy")
      expect(helper.to_label(time)).to eq "yyy"
    end

    it "Enumerableのとき各要素をto_labelしてbrタグ連結した結果を返すこと" do
      expect(helper.to_label([nil, 1, Date.new(2001, 2, 3), "xxx"], "aaa")).to eq "aaa<br>1<br>2001-02-03<br>xxx"
    end

    it "#label, #text, #name, #to_s の優先順で結果を返すこと" do
      o = Object.new
      expect(o).to receive(:to_s).and_return("to_s")
      expect(helper.to_label(o)).to eq "to_s"
      expect(o).to receive(:name).and_return("name")
      expect(helper.to_label(o)).to eq "name"
      expect(o).to receive(:text).and_return("text")
      expect(helper.to_label(o)).to eq "text"
      expect(o).to receive(:label).and_return("label")
      expect(helper.to_label(o)).to eq "label"
    end
  end

  describe "#column_html" do
    before do
      @resource = double("resource", :aaa => "xxx")
      allow(helper).to receive(:controller).and_return(Ar::UsersController.new)
    end

    subject { helper.column_html(@resource, :aaa) }

    it "引数がnilのときnilを返すこと" do
      expect(helper.column_html(nil, nil)).to be nil
      expect(helper.column_html(nil, :aaa)).to be nil
      expect(helper.column_html(@resource, nil)).to be nil
    end

    context '#{controller_name}_#{column_name}_htmlという名前のhelperメソッドが定義されているとき' do
      before { expect(helper).to receive(:ar_users_aaa_html).with(@resource, "xxx").and_return("html") }
      it("その結果を返すこと") { should == "html" }
    end

    context '親クラスの#{controller_name}_#{column_name}_htmlという名前のhelperメソッドが定義されているとき' do
      before { expect(helper).to receive(:users_aaa_html).with(@resource, "xxx").and_return("html") }
      it("その結果を返すこと") { should == "html" }
    end

    context '#{column_name}_htmlという名前のhelperメソッドが定義されているとき' do
      before { expect(helper).to receive(:aaa_html).with(@resource, "xxx").and_return("short_html") }
      it("その結果を返すこと") { should == "short_html" }
    end

    context '#{column_name}_labelという名前のmodelメソッドが定義されているとき' do
      it "その結果を返すこと" do
        expect(@resource).to receive(:aaa_label).and_return("label")
        should == "label"
      end

      it "エスケープされること" do
        expect(@resource).to receive(:aaa_label).and_return("<label>")
        should == "&lt;label&gt;"
      end
    end

    context "どのメソッドも定義されていないとき" do
      it "to_labelの結果がエスケープされること" do
        expect(helper).to receive(:to_label).with(@resource.aaa).and_return("<to_label>")
        should == "&lt;to_label&gt;" 
      end
    end
  end
end
