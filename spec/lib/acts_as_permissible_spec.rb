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

  describe "#permissible" do
    before do
      @p1, @p2 = create_list(:principal, 2)
      @manage, @read, @none = create_list(:event, 3)
      create(:permission, :user => @p1, :permissible => @manage, :flags => Event.flags[:manage])
      create(:permission, :user => @p1, :permissible => @read, :flags => Event.flags[:read])
      create(:permission, :user => @p2, :permissible => @read, :flags => Event.flags[:read])
    end

    it "定義されていない権限を指定した時エラーになること" do
      expect { Event.permissible(@p1, :foo) }.to raise_error(ArgumentError, "permission foo is not defined (must be manage, read, default)")
    end

    it "定義した権限のあるレコードを検索できること" do
      Event.permissible(@p1, :manage).should == [@manage]
      Event.permissible(@p1, :read).should == [@manage, @read]
    end

    it "複数ユーザ指定でレコードを重複なく検索できること" do
      Event.permissible([@p1, @p2], :read).should == [@manage, @read]
    end
  end

  describe "#add_permission" do
    before do
      @event = create(:event)
      @user = create(:principal)
    end

    it "定義されていない権限を指定した時エラーになること" do
      expect { @event.add_permission(@user, :foo) }.to raise_error
    end

    it "権限をシンボルで追加できること" do
      p = @event.add_permission(@user, :manage)
      p.permissible.should == @event
      p.user.should == @user
      p.flags.should == Event.flags[:manage]
    end

    it "権限をフラグで追加できること" do
      p = @event.add_permission(@user, Event.flags[:manage])
      p.permissible.should == @event
      p.user.should == @user
      p.flags.should == Event.flags[:manage]
    end
  end

  describe "#authorized_users" do
    before do
      @p1, @p2, @p3 = create_list(:principal, 3)
      @event = create(:event)
      create(:permission, :user => @p1, :permissible => @event, :flags => Event.flags[:manage])
      create(:permission, :user => @p2, :permissible => @event, :flags => Event.flags[:read])
    end

    it "指定した権限を持つユーザを返すこと" do
      @event.authorized_users(:manage).should == [@p1]
      @event.authorized_users(:read).should == [@p1, @p2]
    end
  end
end
