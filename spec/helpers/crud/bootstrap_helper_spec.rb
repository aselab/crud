# coding: utf-8
require 'spec_helper'

describe Crud::BootstrapHelper do
  context "#active?" do
    let(:nav) { Crud::BootstrapHelper::Context::Nav.new(helper) }

    it "disable_active == true" do
      nav.disable_active = true
      nav.send(:active?, "/", "tab1").should be_false
    end

    it "tab == active_tab" do
      helper.stub(:active_tab).and_return("tab1")
      nav.send(:active?, "/", "tab1").should be_true
      nav.send(:active?, "/", "tab2").should be_false
    end

    it "matcher.is_a?(Proc)" do
      nav.send(:active?, "/", "tab1", -> {true} ).should be_true
      nav.send(:active?, "/", "tab1", -> {false} ).should be_false
    end

    it "matcher.is_a?(Hash)" do
      helper.stub(:params).and_return({:controller => "users", :id => "1", :action => "show"})
      nav.send(:active?, "/", "tab1", {:controller => "users"}).should be_true
      nav.send(:active?, "/", "tab1", {:controller => "users", :id => 1}).should be_true
      nav.send(:active?, "/", "tab1", {:controller => "users", :id => 2}).should be_false
      nav.send(:active?, "/", "tab1", {:controller => "groups"}).should be_false
    end

    it "matcher == url" do
      helper.stub(:url_for).and_return("/users/1")
      nav.send(:active?, "/xxxx", "tab1", "/users/1").should be_true
    end

    it "matcher != url" do
      helper.stub(:url_for).and_return("/users/1")
      nav.send(:active?, "/xxxx", "tab1", "/users/2").should be_false
    end
  end
end
