# coding: utf-8
require 'spec_helper'

describe "acts_as_permissible" do
  describe "#permissions" do
    before do
      @user = create(:user)
      @group = create(:group)
    end

    it "関連が追加されていること" do
      @permission = create(:permission, :user => @user, :permissible => @group)
      expect(@user.permissions).to match_array [@permission]
      expect(@group.permissions).to match_array [@permission]
    end

    it "関連追加するときgroupに設定したデフォルトフラグがセットされること" do
      expect(@group.permissions.build.flags).to eq Group.default_flag
    end
  end

  describe "#permissible" do
    before do
      @p1, @p2 = create_list(:user, 2)
      @manage, @read, @none = create_list(:group, 3)
      create(:permission, :user => @p1, :permissible => @manage, :flags => Group.flags[:manage])
      create(:permission, :user => @p1, :permissible => @read, :flags => Group.flags[:read])
      create(:permission, :user => @p2, :permissible => @read, :flags => Group.flags[:read])
    end

    it "定義されていない権限を指定した時エラーになること" do
      expect { Group.permissible(@p1, :foo) }.to raise_error(ArgumentError, "permission foo is not defined (must be manage, read)")
    end

    it "定義した権限のあるレコードを検索できること" do
      expect(Group.permissible(@p1, :manage)).to match_array [@manage]
      expect(Group.permissible(@p1, :read)).to match_array [@manage, @read]
    end

    it "複数ユーザ指定でレコードを重複なく検索できること" do
      expect(Group.permissible([@p1, @p2], :read)).to match_array [@manage, @read]
    end
  end

  describe "#permissions" do
    before do
      @group = create(:group)
      @user = create(:user)
    end

    describe "#add" do
      it "定義されていない権限を指定した時エラーになること" do
        expect { @group.permissions.add(@user, :foo) }.to raise_error
      end

      it "権限を指定しない場合はデフォルト権限で追加されること" do
        p = @group.permissions.add(@user)
        expect(p.permissible).to eq @group
        expect(p.user).to eq @user
        expect(p.flags).to eq Group.default_flag
      end

      it "権限をシンボルで追加できること" do
        p = @group.permissions.add(@user, :manage)
        expect(p.permissible).to eq @group
        expect(p.user).to eq @user
        expect(p.flags).to eq Group.flags[:manage]
      end

      it "権限をフラグで追加できること" do
        p = @group.permissions.add(@user, Group.flags[:manage])
        expect(p.permissible).to eq @group
        expect(p.user).to eq @user
        expect(p.flags).to eq Group.flags[:manage]
      end

      it "既に権限が追加されている場合、or演算で権限を追加すること" do
        permission = create(:permission, :user => @user, :permissible => @group, :flags => 0b10)
        p = @group.permissions.add(@user, Group.flags[:read])
        expect(p.id).to eq permission.id
        expect(p.flags).to eq 0b11
      end
    end

    describe "#mod" do
      it "定義されていない権限を指定した時エラーになること" do
        expect { @group.permissions.mod(@user, :foo) }.to raise_error
      end

      it "権限をシンボルで変更できること" do
        p = @group.permissions.mod(@user, :manage)
        expect(p.permissible).to eq @group
        expect(p.user).to eq @user
        expect(p.flags).to eq Group.flags[:manage]
      end

      it "権限をフラグで変更できること" do
        p = @group.permissions.mod(@user, Group.flags[:manage])
        expect(p.permissible).to eq @group
        expect(p.user).to eq @user
        expect(p.flags).to eq Group.flags[:manage]
      end

      it "既に権限が追加されている場合、権限を上書きすること" do
        permission = create(:permission, :user => @user, :permissible => @group, :flags => 0b10)
        p = @group.permissions.mod(@user, Group.flags[:read])
        expect(p.id).to eq permission.id
        expect(p.flags).to eq Group.flags[:read]
      end
    end
  end

  describe "#authorized_users" do
    before do
      @p1, @p2, @p3 = create_list(:user, 3)
      @group = create(:group)
      create(:permission, :user => @p1, :permissible => @group, :flags => Group.flags[:manage])
      create(:permission, :user => @p2, :permissible => @group, :flags => Group.flags[:read])
    end

    it "指定した権限を持つユーザを返すこと" do
      expect(@group.authorized_users(:manage)).to match_array [@p1]
      expect(@group.authorized_users(:read)).to match_array [@p1, @p2]
    end
  end

  describe "#permission_translate" do
    it 'permission.#{model_name}.#{permission_name} の翻訳キーとデフォルト値humanizeで翻訳されること' do
      expect(I18n).to receive(:t).with("permission.group.manage", default: "Manage").and_return("翻訳文字列")
      expect(Group.permission_translate(:manage)).to eq "翻訳文字列"
    end
  end

  describe "#permission_label" do
    it "定義されていないフラグを指定した場合はnilを返すこと" do
      expect(Group.permission_label(1111)).to eq nil
    end

    context "restrict is true" do
      it "フラグが完全一致する権限のラベルのみを返すこと" do
        expect(Group).to receive(:permission_translate).with(:read).and_return("read")
        expect(Group.permission_label(0b01, true)).to eq "read"
      end
    end

    context "restrict is false" do
      it "フラグを含むすべての権限のラベルを返すこと" do
        expect(Group).to receive(:permission_translate).with(:manage).and_return("manage")
        expect(Group).to receive(:permission_translate).with(:read).and_return("read")
        expect(Group.permission_label(0b01, false)).to eq "manage,read"
      end
    end
  end
end
