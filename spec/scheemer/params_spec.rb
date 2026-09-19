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

    context "with a list node" do
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

  describe "#each" do
    let(:klass) do
      Class.new do
        extend Scheemer::Params::DSL
      end
    end

    subject(:record) { klass.new({ "someKey" => ["testing"] }) }

    it { expect(record).to respond_to(:each) }

    it "can iterate through the params" do
      expect(record.map(&:to_a)).to eql([["someKey", ["testing"]]])
    end
  end

  describe "#[]" do
    let(:klass) do
      Class.new do
        extend Scheemer::Params::DSL
      end
    end

    subject(:record) { klass.new({ someValue: "testing" }) }

    it "allows lookup with an underscored symbol" do
      expect(record[:some_value]).to eql("testing")
    end

    it "allows lookup with a camelcase string" do
      expect(record["someValue"]).to eql("testing")
    end

    it "allows lookup with a camelcase symbol" do
      expect(record[:someValue]).to eql("testing")
    end

    it "allows lookup with an underscored string" do
      expect(record["some_value"]).to eql("testing")
    end

    it "returns nil for a missing key" do
      expect(record[:missing]).to be_nil
    end

    context "with a nil value" do
      subject(:record) { klass.new({ someValue: nil }) }

      it "distinguishes a present key from a missing key" do
        expect(record[:some_value]).to be_nil
        expect(record.key?(:some_value)).to be true
        expect(record.key?(:missing)).to be false
        expect(record.fetch(:some_value)).to be_nil
      end
    end
  end

  describe "#fetch" do
    let(:klass) do
      Class.new do
        extend Scheemer::Params::DSL
      end
    end

    subject(:record) { klass.new({ someValue: "testing" }) }

    it "returns a matching value" do
      expect(record.fetch(:some_value)).to eql("testing")
    end

    it "returns the default for a missing key" do
      expect(record.fetch(:missing, "fallback")).to eql("fallback")
    end

    it "evaluates a block for a missing key" do
      expect(record.fetch(:missing, &:to_s)).to eql("missing")
    end

    it "raises when no value or default is available" do
      expect { record.fetch(:missing) }.to raise_error(KeyError)
    end
  end

  describe "#key?" do
    let(:klass) do
      Class.new do
        extend Scheemer::Params::DSL
      end
    end

    subject(:record) { klass.new({ someValue: "testing" }) }

    it "recognizes normalized keys" do
      expect(record.key?(:some_value)).to be true
      expect(record).to respond_to(:has_key?)
    end

    it "returns false for a missing key" do
      expect(record.key?(:missing)).to be false
    end
  end

  describe "Hash-compatible readers" do
    let(:klass) do
      Class.new do
        extend Scheemer::Params::DSL
      end
    end

    subject(:record) do
      klass.new({ someValue: { nested_key: "testing" }, otherValue: 1 })
    end

    it "digs through a normalized top-level key" do
      expect(record.dig(:some_value, :nested_key)).to eql("testing")
    end

    it "returns multiple normalized values" do
      expect(record.values_at(:some_value, "other_value", :missing))
        .to eql([{ nested_key: "testing" }, 1, nil])
    end

    it "reports its size and emptiness" do
      expect(record.size).to eq(2)
      expect(record.length).to eq(2)
      expect(record).not_to be_empty
    end

    it "supports implicit hash conversion" do
      expect(Hash(record))
        .to eql({ "some_value" => { nested_key: "testing" }, "other_value" => 1 })
    end
  end

  describe "#to_h" do
    let(:klass) do
      Class.new do
        extend Scheemer::Params::DSL
      end
    end

    context "with a hash node" do
      subject(:record) { klass.new({ "someKey" => ["testing"] }) }

      it "can iterate through the params" do
        expect(record.to_h).to eql({ "some_key" => ["testing"] })
      end
    end

    context "with a list node" do
      subject(:record) { klass.new([{ name: "someKey" }, { name: "testing" }]) }

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

          on_missing path: "content", fallback_to: { fall: "back" }
        end
      end

      subject(:record) { klass.new({ someValue: "testing" }) }

      it "allows access to fields using underscored accessors" do
        expect(record.content).to eql({ fall: "back" })
        expect(record.someValue).to eql("testing")
      end

      it "allows lookup of fallbacks with []" do
        expect(record[:content]).to eql({ fall: "back" })
      end
    end
  end
end
