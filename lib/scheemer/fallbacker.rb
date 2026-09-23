# frozen_string_literal: true

module Scheemer
  module Fallbacker
    extend self

    def apply(params, fallbacks)
      cloned_params = deep_dup(params)

      fallbacks.each do |(path, value)|
        keys = path.to_s.split(".").map(&:to_sym)

        next if deep_key?(cloned_params, keys)

        bury(cloned_params, keys, value.respond_to?(:call) ? value.call : value)
      end

      cloned_params
    end

    private

    def deep_dup(value)
      case value
      when Hash
        value.transform_values { |nested_value| deep_dup(nested_value) }
      when Array
        value.map { |nested_value| deep_dup(nested_value) }
      else
        value
      end
    end

    def deep_key?(hash, keys)
      keys.each_with_index do |key, index|
        return true unless hash.is_a?(Hash)

        matching_key = existing_key(hash, key)
        return false unless matching_key
        return true if index == keys.length - 1

        hash = hash[matching_key]
      end
    end

    def bury(hash, keys, value)
      keys.each_with_index do |key, index|
        matching_key = existing_key(hash, key) || key

        if index == keys.length - 1
          hash[matching_key] = value
        else
          hash[matching_key] ||= {}
          hash = hash[matching_key]
        end
      end
    end

    def existing_key(hash, key)
      return key if hash.key?(key)

      key.to_s if hash.key?(key.to_s)
    end
  end
end
