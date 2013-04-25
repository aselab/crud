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
      @event.permissions.build.flags.should == Event.default_flag
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
      expect { Event.permissible(@p1, :foo) }.to raise_error(ArgumentError, "permission foo is not defined (must be manage, read)")
    end

    it "定義した権限のあるレコードを検索できること" do
      Event.permissible(@p1, :manage).should == [@manage]
      Event.permissible(@p1, :read).should == [@manage, @read]
    end

    it "複数ユーザ指定でレコードを重複なく検索できること" do
      Event.permissible([@p1, @p2], :read).should == [@manage, @read]
    end
  end

  describe "#permissions" do
    before do
      @event = create(:event)
      @user = create(:principal)
    end

    describe "#add" do
      it "定義されていない権限を指定した時エラーになること" do
        expect { @event.permissions.add(@user, :foo) }.to raise_error
      end

      it "権限を指定しない場合はデフォルト権限で追加されること" do
        p = @event.permissions.add(@user)
        p.permissible.should == @event
        p.user.should == @user
        p.flags.should == Event.default_flag
      end

      it "権限をシンボルで追加できること" do
        p = @event.permissions.add(@user, :manage)
        p.permissible.should == @event
        p.user.should == @user
        p.flags.should == Event.flags[:manage]
      end

      it "権限をフラグで追加できること" do
        p = @event.permissions.add(@user, Event.flags[:manage])
        p.permissible.should == @event
        p.user.should == @user
        p.flags.should == Event.flags[:manage]
      end

      it "既に権限が追加されている場合、or演算で権限を追加すること" do
        permission = create(:permission, :user => @user, :permissible => @event, :flags => 0b10)
        p = @event.permissions.add(@user, Event.flags[:read])
        p.id.should == permission.id
        p.flags.should == 0b11
      end
    end

    describe "#mod" do
      it "定義されていない権限を指定した時エラーになること" do
        expect { @event.permissions.mod(@user, :foo) }.to raise_error
      end

      it "権限をシンボルで変更できること" do
        p = @event.permissions.mod(@user, :manage)
        p.permissible.should == @event
        p.user.should == @user
        p.flags.should == Event.flags[:manage]
      end

      it "権限をフラグで変更できること" do
        p = @event.permissions.mod(@user, Event.flags[:manage])
        p.permissible.should == @event
        p.user.should == @user
        p.flags.should == Event.flags[:manage]
      end

      it "既に権限が追加されている場合、権限を上書きすること" do
        permission = create(:permission, :user => @user, :permissible => @event, :flags => 0b10)
        p = @event.permissions.mod(@user, Event.flags[:read])
        p.id.should == permission.id
        p.flags.should == Event.flags[:read]
      end
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

  describe "#permission_translate" do
    it 'permission.#{model_name}.#{permission_name} のキーで翻訳されること' do
      Event.permission_translate(:manage).should == I18n.t("permission.event.manage")
    end

    it "翻訳がない場合はhumanizeした結果を返すこと" do
      Event.permission_translate(:not_exists).should == "Not exists"
    end
  end

  describe "#permission_label" do
    it "定義されていないフラグを指定した場合はnilを返すこと" do
      Event.permission_label(1111).should == nil
    end

    context "restrict is true" do
      it "フラグが完全一致する権限のラベルのみを返すこと" do
        Event.should_receive(:permission_translate).with(:read).and_return("read")
        Event.permission_label(0b01, true).should == "read"
      end
    end

    context "restrict is false" do
      it "フラグを含むすべての権限のラベルを返すこと" do
        Event.should_receive(:permission_translate).with(:manage).and_return("manage")
        Event.should_receive(:permission_translate).with(:read).and_return("read")
        Event.permission_label(0b01, false).should == "manage,read"
      end
    end
  end
end
