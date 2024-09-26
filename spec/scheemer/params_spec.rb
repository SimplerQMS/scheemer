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

      subject(:record) { klass.new({ someValue: "testing" }) }

      it "allows access to fields using underscored accessors" do
        expect(record.some_value).to eql("testing")
      end

      it "allows access to fields using camelcase accessors" do
        expect(record.someValue).to eql("testing")
      end
    end

    context "with a list root node" do
      let(:klass) do
        Class.new do
          extend Scheemer::Params::DSL
        end
      end

      subject(:record) { klass.new([{ name: "testing" }]) }

      it "does not resolve" do
        expect(record.respond_to?(:name)).to be false
      end
    end
  end

  describe ".on_missing" do
    context "with a single level key" do
      let(:klass) do
        Class.new do
          extend Scheemer::Params::DSL

          on_missing path: "content", fallback_to: { fall: "back" }
        end
      end

      subject(:record) { klass.new({ someValue: "testing" }) }

      it "allows access to fields using underscored accessors" do
        expect(record.content).to eql({ fall: "back" })
        expect(record.someValue).to eql("testing")
      end
    end
  end
end
