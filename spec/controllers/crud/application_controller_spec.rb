# coding: utf-8
require 'spec_helper'

describe Crud::ApplicationController do
  let(:model) { }
  before { allow(controller).to receive(:model).and_return(model) }

  describe "#stored_params" do
    before { allow(controller).to receive(:params).and_return("a" => 3, "b" => 4, "c" => 5, "d" => 6) }
    context "キー指定なし" do
      before { expect(controller).to receive(:stored_params_keys).and_return([:a, :c]) }
      it "stored_params_keysのパラメータが保持されること" do
        expect(controller.send(:stored_params)).to eq(a: 3, c: 5)
      end

      it "引数のパラメータで上書きできること" do
        expect(controller.send(:stored_params, c: 1, z: 8)).to eq(a: 3, c: 1, z: 8)
      end
    end

    context "キー指定あり" do
      it "指定したキーのパラメータが保持されること" do
        expect(controller.send(:stored_params, :a, :d)).to eq(a: 3, d: 6)
      end

      it "引数のパラメータで上書きできること" do
        expect(controller.send(:stored_params, :a, :d, x: 1, z: 8)).to eq(a: 3, d: 6, x: 1, z: 8)
      end
    end
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

  describe "#search_condition_for_column" do
    context "ActiveRecord::Base" do
      let(:model) { User }

      it "search_by_xxx メソッドが定義されている場合それを呼び出すこと" do
        cond= ["test = ?", "name1"]
        expect(controller).to receive(:search_by_name).with("name1").and_return(cond)
        expect(controller.send(:search_condition_for_column, "name", "name1")).to eq "test = 'name1'"
      end

      it "仮想カラムを検索できること" do
        s = 3.years.ago.to_date.tomorrow
        e = 2.years.ago.to_date
        cond= {birth_date: s..e}
        expect(controller).to receive(:search_by_age).with("2").and_return(cond)
        expect(controller.send(:search_condition_for_column, "age", "2")).to eq %Q["users"."birth_date" BETWEEN '#{s}' AND '#{e}']
      end

      it "文字列カラムの場合like検索" do
        expect(controller.send(:search_condition_for_column, "name", "name1")).to eq %Q["users"."name" LIKE '%name1%']
      end

      it "数値カラムの場合一致検索" do
        expect(controller.send(:search_condition_for_column, "number", "3")).to eq %Q["users"."number" = 3]
      end
    end

    context "Mongoid::Document" do
      let(:model) { MongoUser }

      it "仮想カラムを検索できること" do
        s = 3.years.ago.to_date.tomorrow
        e = 2.years.ago.to_date
        cond= {birth_date: s..e}
        expect(controller).to receive(:search_by_age).with("2").and_return(cond)
        expect(controller.send(:search_condition_for_column, "age", "2")).to eq cond
      end

      it "文字列カラムの場合regexp検索" do
        expect(controller.send(:search_condition_for_column, "name", "aaa")).to eq("name" => /aaa/)
      end

      it "数値カラムの場合一致検索" do
        expect(controller.send(:search_condition_for_column, "number", "3")).to eq("number" => 3)
      end

      it "Array検索" do
        expect(controller.send(:search_condition_for_column, "array", "aaa")).to eq("array" => "aaa")
      end
    end
  end

end
