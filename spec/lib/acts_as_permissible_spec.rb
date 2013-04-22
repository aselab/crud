# coding: utf-8
require 'spec_helper'

describe "acts_as_permissible" do
  describe "#permissions" do
    before do
      @principal = create(:principal)
      @event = create(:event)
    end

    it "関連が追加されていること" do
      @permission = create(:permission, :principal => @principal, :permissible => @event)
      @principal.permissions.should == [@permission]
      @event.permissions.should == [@permission]
    end

    it "関連追加するときEventに設定したデフォルトフラグがセットされること" do
      @event.permissions.build.flags.should == Event.defined_permissions[:default]
    end
  end

  describe "permissible" do
    before do
      @principal = create(:principal)
      @manage, @read, @none = create_list(:event, 3)
      create(:permission, :principal => @principal, :permissible => @manage, :flags => 0b11)
      create(:permission, :principal => @principal, :permissible => @read, :flags => 0b01)
    end

    it "定義されていない権限を指定した時エラーになること" do
      expect { Event.permissible(@principal, :foo) }.to raise_error(ArgumentError, "action foo is not defined (must be manage, read, default)")
    end

    it "定義した権限のあるレコードを検索できること" do
      Event.permissible(@principal, :manage).should == [@manage]
      Event.permissible(@principal, :read).should == [@manage, @read]
    end
  end
end
