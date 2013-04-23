# coding: utf-8
require 'spec_helper'

describe "acts_as_permissible" do
  describe "#permissions" do
    before do
      @principal = create(:principal)
      @event = create(:event)
    end

    it "関連が追加されていること" do
      @permission = create(:permission, :user => @principal, :permissible => @event)
      @principal.permissions.should == [@permission]
      @event.permissions.should == [@permission]
    end

    it "関連追加するときEventに設定したデフォルトフラグがセットされること" do
      @event.permissions.build.flags.should == Event.flags[:default]
    end
  end

  describe "permissible" do
    before do
      @p1, @p2 = create_list(:principal, 2)
      @manage, @read, @none = create_list(:event, 3)
      create(:permission, :user => @p1, :permissible => @manage, :flags => 0b11)
      create(:permission, :user => @p1, :permissible => @read, :flags => 0b01)
      create(:permission, :user => @p2, :permissible => @read, :flags => 0b01)
    end

    it "定義されていない権限を指定した時エラーになること" do
      expect { Event.permissible(@p1, :foo) }.to raise_error(ArgumentError, "action foo is not defined (must be manage, read, default)")
    end

    it "定義した権限のあるレコードを検索できること" do
      Event.permissible(@p1, :manage).should == [@manage]
      Event.permissible(@p1, :read).should == [@manage, @read]
    end

    it "複数ユーザ指定でレコードを重複なく検索できること" do
      Event.permissible([@p1, @p2], :read).should == [@manage, @read]
    end
  end
end
