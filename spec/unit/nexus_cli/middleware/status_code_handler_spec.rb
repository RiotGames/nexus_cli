require 'spec_helper'

describe NexusCli::Middleware::StatusCodeHandler do
  let(:env) { double(:[] => status_code) }

  describe ":success?" do
    let(:success?) { described_class.success?(env) }

    context "when the status_code is 20X" do
      let(:status_code) { "201" }

      it "returns true" do
        expect(success?).to be_true
      end
    end

    context "when the status_code is not 20X" do
      let(:status_code) { "404" }

      it "returns false" do  
        expect(success?).to be_false
      end
    end
  end

  describe "#on_complete" do
    let(:on_complete) { described_class.new.on_complete(env) }
    let(:status_code) { "404" }

    it "raises an error when not successful" do
      expect{ on_complete }.to raise_error(NexusCli::Errors::HTTPError)
    end
  end
end
