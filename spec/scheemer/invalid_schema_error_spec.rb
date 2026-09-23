# frozen_string_literal: true

require "spec_helper"

RSpec.describe Scheemer::InvalidSchemaError do
  let(:result) do
    Struct.new(:errors).new(
      {
        record: {
          name: ["is missing"],
        },
      }
    )
  end

  subject(:error) { described_class.new(result) }

  it "compiles a semi-readable developer message" do
    expect(error.message).to eql(
      "The submitted request does not satisfy the following requirements: #{error.violations}"
    )
  end

  it "allows access to the violations" do
    expect(error.violations).to eql(
      {
        record: {
          name: ["is missing"],
        },
      }
    )
  end
end
