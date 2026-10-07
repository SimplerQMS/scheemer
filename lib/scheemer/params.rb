# frozen_string_literal: true

require_relative "fallbacker"

require_relative "extensions/string"

require "active_support/core_ext/hash/indifferent_access"

module Scheemer
  # This handles the conversion from the HTTP linguo (camelCase)
  # to Ruby linguo (snake_case), triggers the children's predefined
  # validations and provides accessors for the top level properties
  # of the incoming hash.
  module Params
    using Extensions::CaseModifier

    module DSL
      def self.extended(entity)
        entity.include(InstanceMethods)
      end

      def on_missing(path:, fallback_to:)
        params_fallbacks[path.to_sym] = fallback_to
      end

      def params_fallbacks
        @params_fallbacks ||= {}
      end
    end

    module InstanceMethods
      NOT_GIVEN = Object.new.freeze

      include Enumerable

      def initialize(params, data = {}, fallbacks_applied: false)
        @params = if fallbacks_applied
                    params
                  else
                    Fallbacker.apply(params, self.class.params_fallbacks)
                  end

        validate!(data.to_h) if respond_to?(:validate!)
      end

      def to_h
        ActiveSupport::HashWithIndifferentAccess.new(
          @params.to_h.transform_keys { |key| key.to_s.underscore }
        )
      end

      alias to_hash to_h

      def each(&)
        return enum_for(:each) unless block_given?

        @params.each(&)
      end

      def [](key)
        matching_key = matching_param_key(key)
        @params[matching_key] if matching_key
      end

      def fetch(key, default = NOT_GIVEN)
        matching_key = matching_param_key(key)
        return @params[matching_key] if matching_key
        return yield(key) if block_given?
        return default unless default.equal?(NOT_GIVEN)

        raise KeyError, "key not found: #{key.inspect}"
      end

      def key?(key)
        !matching_param_key(key).nil?
      end

      alias has_key? key?

      def dig(key, *identifiers)
        return @params.dig(key, *identifiers) unless @params.is_a?(Hash)

        value = self[key]
        return value if identifiers.empty? || value.nil?

        value.dig(*identifiers)
      end

      def values_at(*keys)
        return @params.values_at(*keys) unless @params.is_a?(Hash)

        keys.map { |key| self[key] }
      end

      def empty?
        @params.empty?
      end

      def size
        @params.size
      end

      alias length size

      def multi_slice(key)
        matching_key = matching_param_key(key)
        @params.slice(matching_key) if matching_key
      end

      def method_missing(name, *args, &)
        matching_key = matching_param_key(name)
        return @params[matching_key] if matching_key

        super
      end

      def respond_to_missing?(name, include_private = false)
        !matching_param_key(name).nil? || super
      end

      private

      def matching_param_key(key)
        return unless @params.is_a?(Hash)

        key = key.to_sym
        underscored = key.underscore
        return underscored if @params.key?(underscored)

        camelcased = key.camelcase
        return camelcased if @params.key?(camelcased)

        key if @params.key?(key)
      end
    end
  end
end
