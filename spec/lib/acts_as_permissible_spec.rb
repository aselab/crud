# coding: utf-8
require 'spec_helper'

describe "acts_as_permissible" do
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
