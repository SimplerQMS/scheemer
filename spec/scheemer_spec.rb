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
