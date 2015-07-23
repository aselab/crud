require 'spec_helper'

describe Crud::Authorization do
  class FakeController < ApplicationController
    include Crud::Authorization
  end

  before { allow(controller).to receive(:authorization).and_return(authorization) }
  let(:controller) { FakeController.new }
  let(:authorization) { double(:authorization) }
  let(:action) { :action_name }
  let(:resource) { Object.new }
  
  describe "#authorization" do
    class HasAuthorization
      include Crud::Authorization
      class Authorization < Crud::Authorization::Default; end
    end
    class NotHasAuthorization
      include Crud::Authorization
    end

    context "Authorizationクラスが定義されている場合" do
      it { expect(HasAuthorization.new.authorization).to be_a HasAuthorization::Authorization }
    end
    context "Authorizationクラスが定義されていない場合" do
      it { expect(NotHasAuthorization.new.authorization).to be_a Crud::Authorization::Default }
    end
  end

  describe "#authorize_for" do
    subject { controller.authorize_for(action, resource) }
    context "action名と同名のメソッドが定義されている場合" do
      it "呼び出されること" do
        expect(authorization).to receive(action)
        is_expected
      end
    end

    context "action名と同名のメソッドが定義されていない場合" do
      before { expect(controller).to receive(:can?).with(action, resource).and_return(result) }
      context "can?の結果がtrue" do
        let(:result) { true }
        it { expect{subject}.not_to raise_error }
      end
      context "can?の結果がfalse" do
        let(:result) { false }
        it { expect{subject}.to raise_error(Crud::NotAuthorizedError) }
      end
    end
  end

  context "Authorization#can? がtrueの場合" do
    before { expect(authorization).to receive(:can?).with(action, resource).and_return(true) }
    it "#can? should return true" do
      expect(subject.can?(action, resource)).to be true
    end
    it "#cannot? should return false" do
      expect(subject.cannot?(action, resource)).to be false
    end
  end
  context "Authorization#can? がfalseの場合" do
    before { expect(authorization).to receive(:can?).with(action, resource).and_return(false) }
    it "#can? should return false" do
      expect(subject.can?(action, resource)).to be false
    end
    it "#cannot? should return true" do
      expect(subject.cannot?(action, resource)).to be true
    end
  end
end

describe Crud::Authorization::Default do
  subject { Crud::Authorization::Default.new(nil) }
  let(:resource) { Object.new }

  describe "can?" do
    it "アクション名+? メソッドの結果を返すこと" do
      expect(subject).to receive(:action?).with(resource).and_return(false)
      expect(subject.can?(:action, resource)).to be false
    end

    it "アクション名+? メソッドが存在しない場合trueを返すこと" do
      expect(subject.can?(:action, resource)).to be true
    end

    it "結果をキャッシュすること" do
      expect(subject).to receive(:action?).once.with(resource).and_return(false)
      expect(subject.can?(:action, resource)).to be false
      expect(subject.can?(:action, resource)).to be false

    end
  end

  it "new?はcreate?と同じ" do
    expect(subject).to receive(:create?).with(resource).and_return(false)
    expect(subject.new?(resource)).to be false
  end

  it "edit?はupdate?と同じ" do
    expect(subject).to receive(:update?).with(resource).and_return(false)
    expect(subject.edit?(resource)).to be false
  end

  it "create?はmanage?と同じ" do
    expect(subject).to receive(:manage?).with(resource).and_return(false)
    expect(subject.create?(resource)).to be false
  end

  it "update?はmanage?と同じ" do
    expect(subject).to receive(:manage?).with(resource).and_return(false)
    expect(subject.update?(resource)).to be false
  end

  it "destroy?はmanage?と同じ" do
    expect(subject).to receive(:manage?).with(resource).and_return(false)
    expect(subject.destroy?(resource)).to be false
  end
end
