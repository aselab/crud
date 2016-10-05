require 'spec_helper'

shared_examples "permissible common" do
  let(:flags) { permissible_class.flags }
  let(:user1) { create(user_factory) }
  let(:user2) { create(user_factory) }
  let(:group1) { create(group_factory) }
  let(:group2) { create(group_factory) }

  describe ".permissible" do
    before do
      create(permission_factory, user: user1, permissible: group1, flags: flags[:manage])
      create(permission_factory, user: user1, permissible: group2, flags: flags[:read])
      create(permission_factory, user: user2, permissible: group2, flags: flags[:read])
    end

    it "定義されていない権限を指定した時エラーになること" do
      expect { permissible_class.permissible(user1, :foo) }.to raise_error(ArgumentError, "permission foo is not defined (must be manage, read)")
    end

    it "定義した権限のあるレコードを検索できること" do
      expect(permissible_class.permissible(user1, :manage)).to eq [group1]
      expect(permissible_class.permissible(user1, :read)).to eq [group1, group2]
    end

    it "複数ユーザ指定でレコードを重複なく検索できること" do
      expect(permissible_class.permissible([user1, user2], :read)).to eq [group1, group2]
    end

    it "権限を指定しない場合任意の権限で検索すること" do
      expect(permissible_class.permissible(user1)).to eq [group1, group2]
    end
  end

  describe "#permissions" do
    it "関連が追加されていること" do
      permission = group1.permissions.create(user: user1)
      expect(group1.permissions).to eq [permission]
    end

    it "関連追加するときpermissibleに設定したデフォルトフラグがセットされること" do
      expect(group1.permissions.build.flags).to eq permissible_class.default_flag
    end

    describe "#add" do
      it "定義されていない権限を指定した時エラーになること" do
        expect { group1.permissions.add(user1, :foo) }.to raise_error(ArgumentError, "permission foo is not defined (must be manage, read)")
      end

      it "権限を指定しない場合はデフォルト権限で追加されること" do
        p = group1.permissions.add(user1)
        expect(p.permissible).to eq group1
        expect(p.user).to eq user1
        expect(p.flags).to eq permissible_class.default_flag
      end

      it "権限をシンボルで追加できること" do
        p = group1.permissions.add(user1, :manage)
        expect(p.permissible).to eq group1
        expect(p.user).to eq user1
        expect(p.flags).to eq flags[:manage]
      end

      it "権限をフラグで追加できること" do
        p = group1.permissions.add(user1, flags[:manage])
        expect(p.permissible).to eq group1
        expect(p.user).to eq user1
        expect(p.flags).to eq flags[:manage]
      end

      it "既に権限が追加されている場合、or演算で権限を追加すること" do
        permission = create(permission_factory, user: user1, permissible: group1, flags: 0b10)
        p = group1.permissions.add(user1, flags[:read])
        expect(p.id).to eq permission.id
        expect(p.flags).to eq 0b11
      end
    end

    describe "#mod" do
      it "定義されていない権限を指定した時エラーになること" do
        expect { group1.permissions.mod(user1, :foo) }.to raise_error(ArgumentError, "permission foo is not defined (must be manage, read)")
      end

      it "権限をシンボルで変更できること" do
        p = group1.permissions.mod(user1, :manage)
        expect(p.permissible).to eq group1
        expect(p.user).to eq user1
        expect(p.flags).to eq flags[:manage]
      end

      it "権限をフラグで変更できること" do
        p = group1.permissions.mod(user1, flags[:manage])
        expect(p.permissible).to eq group1
        expect(p.user).to eq user1
        expect(p.flags).to eq flags[:manage]
      end

      it "既に権限が追加されている場合、権限を上書きすること" do
        permission = create(permission_factory, user: user1, permissible: group1, flags: 0b10)
        p = group1.permissions.mod(user1, flags[:read])
        expect(p.id).to eq permission.id
        expect(p.flags).to eq flags[:read]
      end
    end
  end

  describe "authorized methods" do
    let!(:user3) { create(user_factory) }
    before do
      create(permission_factory, user: user1, permissible: group1, flags: flags[:manage])
      create(permission_factory, user: user2, permissible: group1, flags: flags[:read])
    end

    describe "#authorized_users" do
      it "指定した権限を持つユーザを返すこと" do
        expect(group1.authorized_users(:manage)).to eq [user1]
        expect(group1.authorized_users(:read)).to eq [user1, user2]
      end
    end

    describe "#authorized?" do
      it "指定した権限を持つ場合true" do
        expect(group1.authorized?(user1, :manage)).to be true
        expect(group1.authorized?(user1, :read)).to be true
        expect(group1.authorized?(user2, :read)).to be true
      end

      it "指定した権限を持たない場合false" do
        expect(group1.authorized?(user2, :manage)).to be false
        expect(group1.authorized?(user3, :read)).to be false
      end

      it "権限を指定しない場合任意の権限でtrue/false" do
        expect(group1.authorized?(user1)).to be true
        expect(group1.authorized?(user2)).to be true
        expect(group1.authorized?(user3)).to be false
      end
    end
  end

  describe ".permission_translate" do
    it 'permission.#{model_key}.#{permission_name} の翻訳キーとデフォルト値humanizeで翻訳されること' do
      expect(I18n).to receive(:t).with("permission.#{permissible_class.model_name.i18n_key}.manage", default: "Manage").and_return("翻訳文字列")
      expect(permissible_class.permission_translate(:manage)).to eq "翻訳文字列"
    end
  end

  describe ".permission_label" do
    it "定義されていないフラグを指定した場合はnilを返すこと" do
      expect(permissible_class.permission_label(1111)).to eq nil
    end

    context "restrict is true" do
      it "フラグが完全一致する権限のラベルのみを返すこと" do
        expect(permissible_class).to receive(:permission_translate).with(:read).and_return("read")
        expect(permissible_class.permission_label(0b01, restrict: true)).to eq "read"
      end
    end

    context "restrict is false" do
      it "フラグを含むすべての権限のラベルを返すこと" do
        expect(permissible_class).to receive(:permission_translate).with(:manage).and_return("manage")
        expect(permissible_class).to receive(:permission_translate).with(:read).and_return("read")
        expect(permissible_class.permission_label(0b01, restrict: false)).to eq "manage,read"
      end
    end
  end
end

describe "acts_as_permissible" do
  context "active_record" do
    let(:permissible_class) { Ar::Group }
    let(:user_factory) { :ar_user }
    let(:group_factory) { :ar_group }
    let(:permission_factory) { :ar_permission }

    include_examples "permissible common"
  end

  context "mongoid" do
    let(:permissible_class) { Mongo::Group }
    let(:user_factory) { :mongo_user }
    let(:group_factory) { :mongo_group }
    let(:permission_factory) { :mongo_permission }

    include_examples "permissible common"

    describe ".split_flag" do
      it "フラグをbit単位に分割して立っている値のみArrayにして返すこと" do |e|
        expect(permissible_class.split_flag(0b10101)).to eq [0b10000,0b100,0b1]
      end

      it "定義したパーミッション名でも分割して返すこと" do |e|
        expect(Mongo::Group.split_flag(:manage)).to eq [0b10,0b1]
      end
    end
  end
end
