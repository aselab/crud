# coding: utf-8
require 'spec_helper'

describe Crud::ApplicationController do
  let(:model) { }
  before { allow(controller).to receive(:model).and_return(model) }

  describe "#stored_params" do
    before {
      params = ActionController::Parameters.new(a: 3, b: 4, c: 5, d: 6)
      allow(controller).to receive(:params).and_return(params)
    }
    context "キー指定なし" do
      before { expect(controller).to receive(:stored_params_keys).and_return([:a, :c]) }
      it "stored_params_keysのパラメータが保持されること" do
        expect(controller.send(:stored_params)).to eq(a: 3, c: 5)
      end

      it "引数のパラメータで上書きできること" do
        expect(controller.send(:stored_params, c: 1, z: 8)).to eq(a: 3, c: 1, z: 8)
      end
    end

    context "キー指定あり" do
      it "指定したキーのパラメータが保持されること" do
        expect(controller.send(:stored_params, :a, :d)).to eq(a: 3, d: 6)
      end

      it "引数のパラメータで上書きできること" do
        expect(controller.send(:stored_params, :a, :d, x: 1, z: 8)).to eq(a: 3, d: 6, x: 1, z: 8)
      end
    end
  end
end
