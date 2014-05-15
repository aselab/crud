# coding: utf-8
require 'spec_helper'

class ActiveRecordModel < ActiveRecord::Base
  has_many :items
end

class MongoidModel
  include Mongoid::Document
  has_many :items
end

describe Crud::ApplicationController do
  let(:model) { ActiveRecordModel }
  before { allow(controller).to receive(:model).and_return(model) }

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

  describe "モデル判定" do

    context "ActiveRecord::Base" do
      let(:model) { ActiveRecordModel }

      it "activerecord? is true" do
        expect(controller.send(:activerecord?)).to be true
      end

      it "mongoid? is false" do
        expect(controller.send(:mongoid?)).to be false
      end
    end

    context "Mongoid::Document" do
      let(:model) { MongoidModel }

      it "activerecord? is false" do
        expect(controller.send(:activerecord?)).to be false
      end

      it "mongoid? is true" do
        expect(controller.send(:mongoid?)).to be true
      end
    end
  end

  [User, MongoUser].each do |m|
    context m do
      let(:model) { m }

      it "#column_metadata" do
        expect(controller.send(:column_metadata, :name)).not_to be nil
        expect(controller.send(:column_metadata, :zzz)).to be nil
      end

      it "#column_type" do
        expect(controller.send(:column_type, :name)).to be :string
        expect(controller.send(:column_type, :birth_date)).to be :date
        expect(controller.send(:column_type, :zzz)).to be nil
      end

      it "#column_key?" do
        expect(controller.send(:column_key?, :name)).to be true
        expect(controller.send(:column_key?, :zzz)).to be false
      end
    end
  end

  describe "#association_key?" do
    [ActiveRecordModel, MongoidModel].each do |m|
      context m do
        let(:model) { m }
        it "関連だったらtrue" do
          expect(controller.send(:association_key?, :items)).to be true
        end
        it "関連でなかったらfalse" do
          expect(controller.send(:association_key?, :zzz)).to be false
        end
      end
    end
  end
end
