# frozen_string_literal: true

require "dry-schema"

Dry::Schema.load_extensions(:hints, :json_schema)

require_relative "errors"

module Scheemer
  class Schema
    module DSL
      def schema(&)
        @schema ||= Schema.new(&)
      end

      def validate_schema(params)
        check_schema_exists!

        @schema.validate(params)
      end

      def validate_schema!(params)
        check_schema_exists!

        @schema.validate!(params)
      end

      def json_schema(loose: false)
        @schema.json_schema(loose:)
      end

      private

      def check_schema_exists!
        return if @schema

        raise NotImplementedError, "Expected `schema { ... }` to have been specified"
      end
    end

    module Types
      include Dry::Types()

      UUID_V7 = Strict::String.constrained(format: /^[0-9(a-f|A-F)]{8}-[0-9(a-f|A-F)]{4}-7[0-9(a-f|A-F)]{3}-[89ab][0-9(a-f|A-F)]{3}-[0-9(a-f|A-F)]{12}$/)
    end

    TypeContainer = ::Dry::Schema::TypeContainer.new
    TypeContainer.register("params.uuid_v7", Types::UUID_V7)

    def initialize(&)
      @definitions = ::Dry::Schema.Params do
        config.types = TypeContainer

        instance_eval(&)
      end
    end

    def validate(params)
      @definitions.call(params)
    end

    def validate!(params)
      validate(params).tap do |result|
        next if result.success?

        raise InvalidSchemaError, result
      end
    end

    def json_schema(loose: false)
      @definitions.json_schema(loose:)
    end
  end
end
