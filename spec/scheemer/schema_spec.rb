# frozen_string_literal: true

require "spec_helper"

RSpec.describe Scheemer::Schema do
  describe ".validate!" do
    subject(:schema) do
      described_class.new do
        required(:test)
        optional(:id).filled(:uuid_v7)
      end
    end

    context "with the required data" do
      it do
        expect { schema.validate!({test: "something"}) }
          .not_to raise_error
      end
    end

    context "without the required data" do
      it do
        expect { schema.validate!({}) }
          .to raise_error(Scheemer::InvalidSchemaError)
      end
    end

    context "when using the UUID v7 custom type" do
      subject(:schema) do
        described_class.new do
          required(:id).filled(:uuid_v7)
        end
      end

      context "with a valid value" do
        it do
          expect { schema.validate!({id: "0196d94e-dde8-74d3-a42e-ee38fa6442a8"}) }
            .not_to raise_error
        end
      end

      context "with an invalid value" do
        it do
          expect { schema.validate!({id: "asd"}) }
            .to raise_error(Scheemer::InvalidSchemaError)
        end
      end
    end
  end
end
