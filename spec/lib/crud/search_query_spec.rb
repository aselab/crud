require 'spec_helper'

describe Crud::SearchQuery do
  describe ".tokenize" do
    subject { Crud::SearchQuery.tokenize(keyword) }
    let(:keyword) { self.class.description }

    context "nil" do
      let(:keyword) { nil }
      it { should eq [] }
    end

    context "空文字" do
      let(:keyword) { "" }
      it { should eq [] }
    end

    context "キーワード1" do
      it { should eq ["キーワード1"] }
    end

    context "キーワード1 キーワード2　 キーワード3" do
      it { should eq ["キーワード1", "キーワード2", "キーワード3"] }
    end

    context 'abc "スペース含む キーワード" def' do
      it { should eq ["abc", "スペース含む キーワード", "def"] }
    end

    context 'key"word "pre' do
      it { should eq ['key"word', '"pre'] }
    end
  end

  describe "active_record" do
    let(:query) { Crud::SearchQuery.new(scope, columns) }
    let(:scope) { Ar::Misc.all }
    let(:columns) { [] }

    describe "#include_associations" do
      subject { query.include_associations }
      let(:columns) { [:string, :integer, :misc_belongings] }
      its(:includes_values) { should eq [:misc_belongings] }
      its(:references_values) { should eq ["misc_belongings"] }
    end
  end
end
