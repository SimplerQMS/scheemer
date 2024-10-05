# frozen_string_literal: true

require "spec_helper"

RSpec.describe Scheemer::Fallbacker do
  context "with a deep level key" do
    subject(:data) do
      described_class.apply(
        { someValue: "testing" },
        { "content.fall.back" => "my-value" }
      )
    end

    it "places the pair" do
      expect(data.dig(:content, :fall, :back)).to eql("my-value")
      expect(data[:someValue]).to eql("testing")
    end
  end

  context "when key exists" do
    subject(:data) do
      described_class.apply(
        { content: { key: "old-key" } },
        { "content.key" => "new-key" }
      )
    end

    it "does not replace the existing value" do
      expect(data.dig(:content, :key)).to eql("old-key")
    end
  end

  context "when parent key exists" do
    subject(:data) do
      described_class.apply(
        { content: { key: "old-key" } },
        { "content" => "new-key" }
      )
    end

    it "does not replace the existing value" do
      expect(data.dig(:content, :key)).to eql("old-key")
    end
  end

  context "when parent key exists and the key is new" do
    subject(:data) do
      described_class.apply(
        { content: { key: "old-key" } },
        { "content.new_key" => "new-value" }
      )
    end

    it "does not replace the existing value" do
      expect(data.dig(:content, :key)).to eql("old-key")
      expect(data.dig(:content, :new_key)).to eql("new-value")
    end
  end

  context "when value is callable" do
    subject(:data) do
      described_class.apply(
        { content: { key: "old-key" } },
        { "content.new_key" => -> { "dynamic-value" } }
      )
    end

    it "does not replace the existing value" do
      expect(data.dig(:content, :key)).to eql("old-key")
      expect(data.dig(:content, :new_key)).to eql("dynamic-value")
    end
  end
end
