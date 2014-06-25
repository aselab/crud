# coding: utf-8
require 'spec_helper'

describe "acts_as_permissible" do
  context "active_record" do
    describe ".permissions" do
      before do
        @user = create(:user)
        @group = create(:group)
      end

      it "関連が追加されていること" do
        @permission = create(:permission, :user => @user, :permissible => @group)
        expect(@user.permissions).to eq [@permission]
        expect(@group.permissions).to eq [@permission]
      end

      it "関連追加するときgroupに設定したデフォルトフラグがセットされること" do
        expect(@group.permissions.build.flags).to eq Group.default_flag
      end
    end

    describe ".permissible" do
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
        expect(Group.permissible(@p1, :manage)).to eq [@manage]
        expect(Group.permissible(@p1, :read)).to eq [@manage, @read]
      end

      it "複数ユーザ指定でレコードを重複なく検索できること" do
        expect(Group.permissible([@p1, @p2], :read)).to eq [@manage, @read]
      end

      it "権限を指定しない場合任意の権限で検索すること" do
        expect(Group.permissible(@p1)).to eq [@manage, @read]
      end
    end

    describe ".permissions" do
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

    describe "instance methods" do
      before do
        @p1, @p2, @p3 = create_list(:user, 3)
        @group = create(:group)
        create(:permission, :user => @p1, :permissible => @group, :flags => Group.flags[:manage])
        create(:permission, :user => @p2, :permissible => @group, :flags => Group.flags[:read])
      end

      describe "#authorized_users" do
        it "指定した権限を持つユーザを返すこと" do
          expect(@group.authorized_users(:manage)).to eq [@p1]
          expect(@group.authorized_users(:read)).to eq [@p1, @p2]
        end
      end

      describe "#authorized?" do
        it "指定した権限を持つ場合true" do
          expect(@group.authorized?(@p1, :manage)).to be true
          expect(@group.authorized?(@p1, :read)).to be true
          expect(@group.authorized?(@p2, :read)).to be true
        end

        it "指定した権限を持たない場合false" do
          expect(@group.authorized?(@p2, :manage)).to be false
          expect(@group.authorized?(@p3, :read)).to be false
        end

        it "権限を指定しない場合任意の権限でtrue/false" do
          expect(@group.authorized?(@p1)).to be true
          expect(@group.authorized?(@p2)).to be true
          expect(@group.authorized?(@p3)).to be false
        end
      end
    end

    describe ".permission_translate" do
      it 'permission.#{model_name}.#{permission_name} の翻訳キーとデフォルト値humanizeで翻訳されること' do
        expect(I18n).to receive(:t).with("permission.group.manage", default: "Manage").and_return("翻訳文字列")
        expect(Group.permission_translate(:manage)).to eq "翻訳文字列"
      end
    end

    describe ".permission_label" do
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

  context "mongoid" do
    describe ".permissions" do
      before do
        @user = create(:mongo_user)
        @group = create(:mongo_group)
      end

      it "関連追加するときgroupに設定したデフォルトフラグがセットされること" do
        expect(@group.mongo_permissions.build.flags).to eq [1]
      end
    end

    describe ".permissible" do
      before do
        @u1, @u2, @u3 = create_list(:mongo_user, 3)
        @manage, @read, @none = create_list(:mongo_group, 3)
        @manage.mongo_permissions.create(mongo_user: @u1, flags: [2, 1])
        @read.mongo_permissions.create(mongo_user: @u1, flags: [1])
        @read.mongo_permissions.create(mongo_user: @u2, flags: [1])
        @read.mongo_permissions.create(mongo_user: @u3, flags: [2])
      end

      it "定義されていない権限を指定した時エラーになること" do
        expect { MongoGroup.permissible(@u1, :foo) }.to raise_error(ArgumentError, "permission foo is not defined (must be manage, read)")
      end

      it "定義した権限のあるレコードを検索できること" do
        expect(MongoGroup.permissible(@u1, :manage)).to eq [@manage]
        expect(MongoGroup.permissible(@u1, :read)).to eq [@manage, @read]
      end

      it "複数ユーザ指定でレコードを重複なく検索できること" do
        expect(MongoGroup.permissible([@u1, @u2], :read)).to eq [@manage, @read]
      end

      it "ユーザと権限がor検索になっていないこと($elemMatchであること)" do
        expect(MongoGroup.permissible(@u2, :manage)).to be_empty
      end

      it "権限を指定しない場合任意の権限で検索すること" do
        expect(MongoGroup.permissible(@u1)).to eq [@manage, @read]
      end
    end

    describe ".split_flag" do
      it "フラグをbit単位に分割して立っている値のみArrayにして返すこと" do |e|
        expect(MongoGroup.split_flag(0b10101)).to eq [0b10000,0b100,0b1]
      end

      it "定義したパーミッション名でも分割して返すこと" do |e|
        expect(MongoGroup.split_flag(:manage)).to eq [0b10,0b1]
      end
    end

    describe ".permissions" do
      before do
        @group = create(:mongo_group)
        @user = create(:mongo_user)
      end

      describe "#add" do
        it "定義されていない権限を指定した時エラーになること" do
          expect { @group.mongo_permissions.add(@user, :foo) }.to raise_error
        end

        it "権限を指定しない場合はデフォルト権限で追加されること" do
          p = @group.mongo_permissions.add(@user)
          expect(p.mongo_user).to eq @user
          expect(p.flags).to eq [1]
        end

        it "権限をシンボルで追加できること" do
          p = @group.mongo_permissions.add(@user, :manage)
          expect(p.mongo_user).to eq @user
          expect(p.flags).to match_array [2,1]
        end

        it "権限をフラグで追加できること" do
          p = @group.mongo_permissions.add(@user, 0b10011)
          expect(p.mongo_user).to eq @user
          expect(p.flags).to match_array [0b10000, 0b10, 0b1]
        end

        it "既に権限が設定されている場合、権限を追加すること" do
          permission = @group.mongo_permissions.create(mongo_user: @user, flags: [0b10])
          p = @group.mongo_permissions.add(@user, 0b01)
          expect(p.id).to eq permission.id
          expect(p.flags).to match_array [0b10, 0b01]
        end
      end

      describe "#mod" do
        it "定義されていない権限を指定した時エラーになること" do
          expect { @group.mongo_permissions.mod(@user, :foo) }.to raise_error
        end

        it "権限をシンボルで変更できること" do
          p = @group.mongo_permissions.mod(@user, :manage)
          expect(p.mongo_user).to eq @user
          expect(p.flags).to match_array [2,1]
        end

        it "権限をフラグで変更できること" do
          p = @group.mongo_permissions.mod(@user, 0b10011)
          expect(p.mongo_user).to eq @user
          expect(p.flags).to match_array [0b10000, 0b10, 0b1]
        end

        it "既に権限が追加されている場合、権限を上書きすること" do
          permission = @group.mongo_permissions.create(mongo_user: @user, flags: [0b10])
          p = @group.mongo_permissions.mod(@user, 0b01)
          expect(p.id).to eq permission.id
          expect(p.flags).to eq [0b01]
        end
      end
    end

    describe "instance methods" do
      before do
        @p1, @p2, @p3 = create_list(:mongo_user, 3)
        @group = create(:mongo_group)
        @group.mongo_permissions.create(:mongo_user => @p1, :flags => [2, 1])
        @group.mongo_permissions.create(:mongo_user => @p2, :flags => [1])
      end

      describe "#users" do
        it "権限を持つ全てのユーザを返すこと" do
          expect(@group.mongo_users).to eq [@p1, @p2]
        end
      end

      describe "#authorized_users" do
        it "指定した権限を持つユーザを返すこと" do
          expect(@group.authorized_mongo_users(:manage)).to eq [@p1]
          expect(@group.authorized_mongo_users(:read)).to eq [@p1, @p2]
        end
      end

      describe "#authorized?" do
        it "指定した権限を持つ場合true" do
          expect(@group.authorized?(@p1, :manage)).to be true
          expect(@group.authorized?(@p1, :read)).to be true
          expect(@group.authorized?(@p2, :read)).to be true
        end

        it "指定した権限を持たない場合false" do
          expect(@group.authorized?(@p2, :manage)).to be false
          expect(@group.authorized?(@p3, :read)).to be false
        end

        it "権限を指定しない場合任意の権限でtrue/false" do
          expect(@group.authorized?(@p1)).to be true
          expect(@group.authorized?(@p2)).to be true
          expect(@group.authorized?(@p3)).to be false
        end
      end
    end
  end
end
