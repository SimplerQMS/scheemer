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

      def validate_schema!(params, ignored_paths: [])
        check_schema_exists!

        @schema.validate!(params, ignored_paths:)
      end

      def schema_key_names
        check_schema_exists!

        @schema.key_names
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

      # rubocop:todo Layout/LineLength
      UUID_V7 = Strict::String.constrained(format: /^[0-9(a-f|A-F)]{8}-[0-9(a-f|A-F)]{4}-7[0-9(a-f|A-F)]{3}-[89ab][0-9(a-f|A-F)]{3}-[0-9(a-f|A-F)]{12}$/)
      # rubocop:enable Layout/LineLength
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

    FilteredResult = Struct.new(:errors)

    # Errors at or below any of `ignored_paths` (arrays of keys) are dropped;
    # an error is raised only if others remain.
    def validate!(params, ignored_paths: [])
      validate(params).tap do |result|
        next if result.success?

        errors = result.errors
        remaining = errors.reject { |message| ignored_path?(message.path, ignored_paths) }
        next if remaining.empty?

        raise InvalidSchemaError, result if remaining.size == errors.count

        raise InvalidSchemaError, FilteredResult.new(::Dry::Schema::MessageSet.new(remaining, errors.options))
      end
    end

    def ignored_path?(path, ignored_paths)
      ignored_paths.any? { |ignored_path| path.first(ignored_path.size) == ignored_path }
    end

    def key_names
      @definitions.key_map.map { |key| key.name.to_sym }
    end

    def json_schema(loose: false)
      @definitions.json_schema(loose:)
    end
  end
end
