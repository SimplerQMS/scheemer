# frozen_string_literal: true

module PerformanceWorkloads
  MODES = %i[flat wrapped legacy].freeze
  STATES = %i[none supplied missing].freeze

  def params_class(mode, defaults, library)
    klass = Class.new { extend library::DSL }
    klass.params_mode(mode, root: (mode == :wrapped ? :config : nil)) unless mode == :legacy
    define_schema(klass, mode)
    define_defaults(klass) if defaults

    klass
  end

  def define_schema(klass, mode)
    fields = proc do
      required(:name).filled(:string)
      optional(:page).filled(:integer)
      optional(:settings).hash { optional(:mode).filled(:string) }
      optional(:tags).array(:string)
    end

    klass.schema do
      mode == :flat ? instance_eval(&fields) : required(:config).hash(&fields)
    end
  end

  def define_defaults(klass)
    klass.on_missing path: "page", fallback_to: "2"
    klass.on_missing path: "settings.mode", fallback_to: "standard"
    klass.on_missing path: "tags", fallback_to: -> { [] }
  end

  def constructor_workloads(library)
    MODES.product(STATES, [0, 128]).to_h do |mode, state, size|
      klass = params_class(mode, state != :none, library)
      payload = { name: "example" }
      payload.merge!(page: "3", settings: { mode: "custom" }, tags: []) if state == :supplied
      payload[:tags] = Array.new(size) { "tag" } if size.positive?
      input = mode == :flat ? payload : { config: payload }

      ["construct/#{mode}/#{state}/#{size}", -> { klass.new(input) }]
    end
  end

  def lookup_workloads(library)
    klass = Class.new { extend library::Params::DSL }
    record = klass.new({ some_value: "snake", otherValue: "camel", nilValue: nil, active: false })

    {
      "read/snake" => -> { record[:some_value] },
      "read/camel" => -> { record[:other_value] },
      "read/missing" => -> { record[:missing] },
      "read/method" => -> { record.other_value },
      "read/fetch_nil" => -> { record.fetch(:nil_value) },
      "read/key_false" => -> { record.key?(:active) },
    }
  end
end
