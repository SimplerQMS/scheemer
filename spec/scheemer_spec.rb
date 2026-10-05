# frozen_string_literal: true

require "spec_helper"

RSpec.describe Scheemer do
  it "has a version number" do
    expect(Scheemer::VERSION).not_to be_nil
  end

  describe "DSL" do
    context "with a defined schema" do
      let(:klass) do
        Class.new do
          extend Scheemer::DSL

          schema do
            required(:root).hash do
              required(:someValue).filled(:string)
            end
          end
        end
      end

      subject(:record) { klass.new({ root: { someValue: "testing" } }) }

      it "allows access to fields using underscored accessors" do
        expect(record.some_value).to eql("testing")
      end
    end

    context "with flat params" do
      let(:klass) do
        Class.new do
          extend Scheemer::DSL

          params_mode :flat

          schema do
            required(:name).filled(:string)
            required(:active).filled(:bool)
          end
        end
      end

      subject(:record) { klass.new({ name: "testing", active: true }) }

      it "keeps the complete validated result" do
        expect(record.to_h).to eql({ "name" => "testing", "active" => true })
      end
    end

    context "with schema-validated fallbacks" do
      let(:klass) do
        Class.new do
          extend Scheemer::DSL

          params_mode :flat

          schema do
            required(:attention_level).filled(:string, included_in?: %w[direct_attention ambient])
            required(:settings).hash do
              required(:mode).filled(:string)
            end
            required(:request_id).filled(:string)
          end

          on_missing path: :attention_level, fallback_to: "direct_attention"
          on_missing path: "settings.mode", fallback_to: "standard"
          on_missing path: :request_id, fallback_to: -> { "generated-request-id" }
        end
      end

      it "validates and exposes a fallback for a missing required field" do
        record = klass.new(settings: { mode: "custom" })

        expect(record.attention_level).to eql("direct_attention")
      end

      it "preserves a supplied value instead of its fallback" do
        record = klass.new(attention_level: "ambient", settings: { mode: "custom" })

        expect(record.attention_level).to eql("ambient")
      end

      it "applies fallbacks at nested paths" do
        record = klass.new(attention_level: "ambient", settings: {})

        expect(record.dig(:settings, :mode)).to eql("standard")
      end

      it "evaluates a callable fallback only for a missing path" do
        fallback = -> { "generated-request-id" }
        allow(fallback).to receive(:call).and_call_original
        klass.on_missing path: :request_id, fallback_to: fallback

        klass.new(attention_level: "ambient", settings: { mode: "custom" }, request_id: "supplied")

        expect(fallback).not_to have_received(:call)
      end

      it "does not validate fallback values" do
        klass.on_missing path: :attention_level, fallback_to: "invalid"

        expect(klass.new(settings: { mode: "custom" }).attention_level).to eql("invalid")
      end

      it "still validates the same value when the caller supplies it" do
        expect { klass.new(attention_level: "invalid", settings: { mode: "custom" }) }
          .to raise_error(Scheemer::InvalidSchemaError)
      end
    end

    context "with fallbacks that do not satisfy the schema" do
      let(:klass) do
        Class.new do
          extend Scheemer::DSL

          params_mode :flat

          schema do
            optional(:state).array(:string)
            optional(:batch_id).filled(:string)
            optional(:id).filled(:uuid_v7)
            optional(:indirect_actor).value(included_in?: %w[author reviewer approver responsible])
            optional(:name).filled(:string)
          end

          on_missing path: "state", fallback_to: "active"
          on_missing path: "batch_id", fallback_to: -> {}
          on_missing path: "id", fallback_to: -> {}
          on_missing path: "indirect_actor", fallback_to: []
        end
      end

      it "exposes the defaults exactly as declared" do
        expect(klass.call({})).to eql(
          { "state" => "active", "batch_id" => nil, "id" => nil, "indirect_actor" => [] }
        )
      end

      it "validates a mismatched value supplied by the caller" do
        expect { klass.call(state: "active") }
          .to raise_error(Scheemer::InvalidSchemaError) { |error| expect(error.violations).to have_key(:state) }
      end

      it "validates a nil value supplied by the caller" do
        expect { klass.call(batch_id: nil) }.to raise_error(Scheemer::InvalidSchemaError)
      end

      it "validates an excluded value supplied by the caller" do
        expect { klass.call(indirect_actor: "nobody") }.to raise_error(Scheemer::InvalidSchemaError)
      end

      it "reports only the caller-supplied errors" do
        expect { klass.call(name: 1) }
          .to raise_error(Scheemer::InvalidSchemaError) { |error|
            expect(error.violations).to eql({ name: ["must be a string"] })
          }
      end
    end

    context "with fallbacks that opt into validation" do
      let(:klass) do
        Class.new do
          extend Scheemer::DSL

          params_mode :wrapped, root: :config

          schema do
            required(:config).hash do
              optional(:state).array(:string)
              optional(:page).filled(:integer)
              optional(:name).filled(:string)
            end
          end

          on_missing path: "state", fallback_to: "active", validate: true
          on_missing path: "page", fallback_to: "2", validate: true
          on_missing path: "name", fallback_to: nil
        end
      end

      it "raises when the default does not satisfy the schema" do
        expect { klass.call(config: {}) }
          .to raise_error(Scheemer::InvalidSchemaError) { |error|
            expect(error.violations).to eql({ config: { state: ["must be an array"] } })
          }
      end

      it "exposes a valid default as coerced by the schema" do
        klass.on_missing path: "state", fallback_to: ["active"], validate: true

        expect(klass.call(config: {})).to eql({ "state" => ["active"], "page" => 2, "name" => nil })
      end

      it "stops validating a default declared again without the option" do
        klass.on_missing path: "state", fallback_to: "active"

        expect(klass.call(config: {})["state"]).to eql("active")
      end
    end

    context "with a callable fallback returning a mutable value" do
      let(:klass) do
        Class.new do
          extend Scheemer::DSL

          params_mode :flat

          schema do
            optional(:tags).array(:string)
          end

          on_missing path: "tags", fallback_to: -> { [] }
        end
      end

      it "returns a fresh value to each instance" do
        klass.new({}).tags << "mutated"

        expect(klass.new({}).tags).to eql([])
      end
    end

    context "with fallbacks in wrapped mode" do
      let(:klass) do
        Class.new do
          extend Scheemer::DSL

          params_mode :wrapped, root: :config

          schema do
            required(:config).hash do
              optional(:primary).filled(:bool)
              required(:level).filled(:string)
            end
          end

          on_missing path: "primary", fallback_to: false
        end
      end

      it "resolves paths relative to the root" do
        klass.on_missing path: "level", fallback_to: "x"

        expect(klass.call(config: {})).to eql({ "primary" => false, "level" => "x" })
      end

      it "fills a missing required key" do
        klass.on_missing path: "level", fallback_to: "x"

        expect(klass.new(config: {}).level).to eql("x")
      end

      it "accepts a path that already starts with the root" do
        klass.on_missing path: "config.level", fallback_to: "x"

        expect(klass.call(config: {})).to eql({ "primary" => false, "level" => "x" })
      end
    end

    context "with fallbacks in legacy mode" do
      let(:klass) do
        Class.new do
          extend Scheemer::DSL

          schema do
            optional(:metadata).hash
            required(:root).hash do
              optional(:settings).hash do
                optional(:mode).filled(:string)
              end
            end
          end

          on_missing path: "settings.mode", fallback_to: "standard"
        end
      end

      it "resolves paths relative to the exposed root node" do
        record = klass.new("root" => { "settings" => {} })

        expect(record.dig(:settings, :mode)).to eql("standard")
      end

      it "preserves a supplied value" do
        record = klass.new(root: { settings: { mode: "custom" } })

        expect(record.dig(:settings, :mode)).to eql("custom")
      end
    end

    context "with explicitly wrapped params" do
      let(:klass) do
        Class.new do
          extend Scheemer::DSL

          params_mode :wrapped, root: :user

          schema do
            required(:metadata).hash
            required(:user).hash do
              required(:name).filled(:string)
            end
          end
        end
      end

      subject(:record) { klass.new({ metadata: {}, user: { name: "testing" } }) }

      it "unwraps the configured root rather than the first value" do
        expect(record.to_h).to eql({ "name" => "testing" })
      end
    end

    describe ".params_mode" do
      let(:klass) do
        Class.new do
          extend Scheemer::DSL
        end
      end

      it "requires wrapped params to name their root" do
        expect { klass.params_mode(:wrapped) }
          .to raise_error(ArgumentError, /specify a root/)
      end

      it "rejects a root for flat params" do
        expect { klass.params_mode(:flat, root: :user) }
          .to raise_error(ArgumentError, /does not accept a root/)
      end

      it "rejects unknown modes" do
        expect { klass.params_mode(:unknown) }
          .to raise_error(ArgumentError, /flat, wrapped/)
      end
    end

    describe ".call" do
      let(:klass) do
        Class.new do
          extend Scheemer::DSL

          params_mode :flat

          schema do
            required(:someValue).filled(:string)
          end
        end
      end

      it "validates params and returns a hash" do
        expect(klass.call({ someValue: "testing" }))
          .to eql({ "some_value" => "testing" })
      end
    end

    context "when passing in extra context data" do
      let(:klass) do
        Class.new do
          extend Scheemer::DSL

          schema do
            required(:root).hash do
              required(:someValue).filled(:string)
            end
          end
        end
      end

      it do
        expect_any_instance_of(klass)
          .to receive(:validate!).with(other_data: "it works!")

        klass.new({ root: { someValue: "testing" } }, other_data: "it works!")
      end
    end

    context "without a defined schema" do
      let(:klass) do
        Class.new do
          extend Scheemer::DSL
        end
      end

      it { expect { klass.new({}) }.to raise_error(NotImplementedError) }
    end
  end

  describe "#each" do
    context "with a flat hash" do
      let(:klass) do
        Class.new do
          extend Scheemer::DSL

          schema do
            required(:root).hash do
              required(:name).filled(:string)
            end
          end
        end
      end

      subject(:record) { klass.new({ root: { name: "testing" } }) }

      it { expect(record).to respond_to(:each) }
    end

    context "with a list as the root node" do
      let(:klass) do
        Class.new do
          extend Scheemer::DSL

          schema do
            required(:root).hash do
              required(:children).array(:string)
            end
          end
        end
      end

      subject(:record) { klass.new({ root: { children: ["testing"] } }) }

      it "can iterate through the params" do
        expect(record.map(&:to_a)).to eql([[:children, ["testing"]]])
      end
    end

    context "with a hash as the root node" do
      let(:klass) do
        Class.new do
          extend Scheemer::DSL

          schema do
            required(:children).array(:hash)
          end
        end
      end

      subject(:record) { klass.new({ children: [{ name: "testing" }] }) }

      it "can iterate through the params" do
        expect(record.first).to eql({ name: "testing" })
      end
    end
  end
end
