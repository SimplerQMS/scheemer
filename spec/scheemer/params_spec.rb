# frozen_string_literal: true

require "spec_helper"

RSpec.describe Scheemer::Params do
  describe ".new" do
    context "with a defined set structure" do
      let(:klass) do
        Class.new do
          extend Scheemer::Params::DSL
        end
      end

      subject(:record) { klass.new({someValue: "testing"}) }

      it "allows access to fields using underscored accessors" do
        expect(record.some_value).to eql("testing")
      end

      it "allows access to fields using camelcase accessors" do
        expect(record.someValue).to eql("testing")
      end
    end

    context "with a list node" do
      let(:klass) do
        Class.new do
          extend Scheemer::Params::DSL
        end
      end

      subject(:record) { klass.new([{name: "testing"}]) }

      it "does not resolve" do
        expect(record.respond_to?(:name)).to be false
      end
    end
  end

  describe "#each" do
    let(:klass) do
      Class.new do
        extend Scheemer::Params::DSL
      end
    end

    subject(:record) { klass.new({"someKey" => ["testing"]}) }

    it { expect(record.respond_to?(:each)).to be_truthy }

    it "can iterate through the params" do
      expect(record.map(&:to_a)).to eql([["someKey", ["testing"]]])
    end
  end

  describe "#to_h" do
    let(:klass) do
      Class.new do
        extend Scheemer::Params::DSL
      end
    end

    context "with a hash node" do
      subject(:record) { klass.new({"someKey" => ["testing"]}) }

      it "can iterate through the params" do
        expect(record.to_h).to eql({"some_key" => ["testing"]})
      end
    end

    context "with a list node" do
      subject(:record) { klass.new([{name: "someKey"}, {name: "testing"}]) }

      it "can iterate through the params" do
        expect { record.to_h }.to raise_error(TypeError)
      end
    end
  end

  describe ".on_missing" do
    context "with a single level key" do
      let(:klass) do
        Class.new do
          extend Scheemer::Params::DSL

          on_missing path: "content", fallback_to: {fall: "back"}
        end
      end

      subject(:record) { klass.new({someValue: "testing"}) }

      it "allows access to fields using underscored accessors" do
        expect(record.content).to eql({fall: "back"})
        expect(record.someValue).to eql("testing")
      end
    end
  end
end
