require 'spec_helper'

describe Crud::ApplicationController::DefaultAuthorization do
  subject { Crud::ApplicationController::DefaultAuthorization.new(nil) }
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
