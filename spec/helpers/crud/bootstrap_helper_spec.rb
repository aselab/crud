# coding: utf-8
require 'spec_helper'

describe Crud::BootstrapHelper do
  describe "#bootstrap_flash_messages" do
    subject { helper.bootstrap_flash_messages }

    context "flash error" do
      before { flash[:error] = "error message" }
      it { should include "alert-danger" }
      it { should include "error message" }
    end

    context "flash alert" do
      before { flash[:alert] = "alert message" }
      it { should include "alert-warning" }
      it { should include "alert message" }
    end

    context "flash notice" do
      before { flash[:notice] = "notice message" }
      it { should include "alert-success" }
      it { should include "notice message" }
    end
  end

  context "#active?" do
    let(:nav) { Crud::BootstrapHelper::Context::Nav.new(helper) }

    it "disable_active == true" do
      nav.disable_active = true
      expect(nav.send(:active?, "/", "tab1")).to be false
    end

    it "tab == active_tab" do
      allow(helper).to receive(:active_tab).and_return("tab1")
      expect(nav.send(:active?, "/", "tab1")).to be true
      expect(nav.send(:active?, "/", "tab2")).to be false
    end

    it "matcher.is_a?(Proc)" do
      expect(nav.send(:active?, "/", "tab1", -> {true} )).to be true
      expect(nav.send(:active?, "/", "tab1", -> {false} )).to be false
    end

    it "matcher.is_a?(Hash)" do
      allow(helper).to receive(:params).and_return({:controller => "users", :id => "1", :action => "show"})
      expect(nav.send(:active?, "/", "tab1", {:controller => "users"})).to be true
      expect(nav.send(:active?, "/", "tab1", {:controller => "users", :id => 1})).to be true
      expect(nav.send(:active?, "/", "tab1", {:controller => "users", :id => 2})).to be false
      expect(nav.send(:active?, "/", "tab1", {:controller => "groups"})).to be false
    end

    it "matcher == url" do
      allow(helper).to receive(:url_for).and_return("/users/1")
      expect(nav.send(:active?, "/xxxx", "tab1", "/users/1")).to be true
    end

    it "matcher != url" do
      allow(helper).to receive(:url_for).and_return("/users/1")
      expect(nav.send(:active?, "/xxxx", "tab1", "/users/2")).to be false
    end
  end
end
