# frozen_string_literal: true

module Scheemer
  module DSL
    PARAMS_MODES = %i[flat wrapped].freeze

    def self.extended(entity)
      entity.extend(Schema::DSL)
      entity.extend(Params::DSL)
      entity.include(InstanceMethods)
    end

    def params_mode(mode, root: nil)
      unless PARAMS_MODES.include?(mode)
        raise ArgumentError, "Expected params mode to be one of: #{PARAMS_MODES.join(', ')}"
      end
      raise ArgumentError, "Expected wrapped params mode to specify a root" if mode == :wrapped && root.nil?
      raise ArgumentError, "Flat params mode does not accept a root" if mode == :flat && root

      @params_mode_configuration = { mode:, root: root&.to_sym }.freeze
    end

    def params_mode_configuration
      @params_mode_configuration || { mode: :legacy }.freeze
    end

    def call(params, data = {})
      new(params, data).to_h
    end
  end

  module InstanceMethods
    def initialize(params, data = {})
      all_params = (params.respond_to?(:permit!) ? params.permit! : params).to_h
      params_with_fallbacks = apply_fallbacks(all_params)
      permitted = self.class.validate_schema!(params_with_fallbacks)

      root_node = extract_root_node(permitted.to_h)

      super(root_node, data.to_h, fallbacks_applied: true)
    end

    private

    def apply_fallbacks(all_params)
      paths = scoped_paths(all_params)
      fallbacks = self.class.params_fallbacks.slice(*paths.keys).transform_keys(paths)

      Fallbacker.apply(all_params, fallbacks)
    end

    # Maps each declared fallback path to a path from the top of the input.
    # Fallback paths are relative to the node exposed by the params object;
    # in wrapped mode, a path that already starts with the root is kept as is.
    def scoped_paths(all_params)
      declared = self.class.params_fallbacks.keys
      configuration = self.class.params_mode_configuration

      case configuration[:mode]
      when :flat
        declared.to_h { |path| [path, path] }
      when :wrapped
        declared.to_h { |path| [path, prefix_path(path, configuration[:root], skip_if_present: true)] }
      else
        legacy_scoped_paths(declared, all_params)
      end
    end

    def legacy_scoped_paths(declared, all_params)
      root = legacy_root_key(all_params)
      return {} unless root

      declared.to_h { |path| [path, prefix_path(path, root)] }
    end

    def prefix_path(path, root, skip_if_present: false)
      return path if skip_if_present && path.to_s.split(".").first == root.to_s

      :"#{root}.#{path}"
    end

    def legacy_root_key(all_params)
      self.class.schema_key_names.find do |name|
        all_params.key?(name) || all_params.key?(name.to_s)
      end
    end

    def extract_root_node(permitted)
      configuration = self.class.params_mode_configuration

      case configuration[:mode]
      when :flat
        permitted
      when :wrapped
        permitted.fetch(configuration[:root])
      else
        permitted.values.first
      end
    end
  end
end

require_relative "scheemer/errors"
require_relative "scheemer/params"
require_relative "scheemer/schema"
require_relative "scheemer/version"
