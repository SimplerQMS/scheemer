# Scheemer

Scheemer uses [Dry::Schema](https://github.com/dry-rb/dry-schema) to
enable us to write consistent looking structural parameter validation
and data accessing on our services.

## Usage

### Using the Scheemer

Scheemer::DSL ties together the parameters key translation and
structural validation.

```ruby
klass = Class.new do
  extend Scheemer::DSL

  params_mode :wrapped, root: :root

  schema do
    required(:root).hash do
      required(:someValue).filled(:string)
    end
  end

  on_missing path: "book.author.name", fallback_to: { "Stephen King" }
end

record = klass.new({ root: { someValue: "testing" } })
record.some_value # => "testing"
record.book.dig(:author, :name) # => "Stephen King"
```

Use flat mode when an endpoint does not wrap its parameters in a resource key:

```ruby
class IndexParams
  extend Scheemer::DSL

  params_mode :flat

  schema do
    optional(:status).filled(:string)
    optional(:page).filled(:integer)
  end
end

record = IndexParams.new({ status: "open", page: 2 })
record[:status] # => "open"

# Validate and return a hash without retaining the Params object.
IndexParams.call({ status: "open", page: 2 })
# => { "status" => "open", "page" => 2 }
```

Wrapped mode requires an explicit root and unwraps that key after validation.
Classes without a declared mode retain the legacy behavior of unwrapping the
first validated value.

#### Optional Extra Data

When using the DSL, it's possible to inject extra parameters into your
custom validations through the constructor. This can be helpful in
cases where validations require access to outside data (e.g. database
records, user session).

```ruby
klass = Class.new do
  extend Scheemer::DSL

  schema do
    required(:root).hash do
      required(:someValue).filled(:string)
    end
  end

  def validate!(data)
    p data[:records] # => [ ... ]
    p data[:some_extra_value] # => "may be for validation"
  end
end
record = klass.new(
  { root: { someValue: "testing" } },
  { records: [1, 2], some_extra_value: "may be for validation" }
)
```

### Using Scheemer::Params

Scheemer::Params handles the parameters key translation.

```ruby
klass = Class.new do
  extend Scheemer::Params::DSL

  def initialize(...)
    super

    ...
  end
end

record = klass.new({ someValue: "testing" })
record.some_value # => "testing"
record[:some_value] # => "testing"
record["someValue"] # => "testing"
record.fetch(:some_value) # => "testing"
record.key?(:some_value) # => true
record.dig(:some_value) # => "testing"
record.values_at(:some_value) # => ["testing"]
record.size # => 1
record.empty? # => false
record.to_hash # => { "some_value" => "testing" }
```

Key translation applies to top-level access only. Values returned from nested
hashes are ordinary hashes, so their keys retain the spelling used in the
returned data.

### Using Scheemer::Schema

Scheemer::Schema::DSL handles the structural validation.

```ruby
klass = Class.new do
  extend Scheemer::Schema::DSL

  schema do
    required(:name).filled(:string)
  end

  attr_reader :contents

  def initialize(params)
    @contents = self.class.validate_schema!(params)
  end
end

klass.new({ name: 1 }) # => Error:'{:name=>['must be a string"]}"
```

## Development

```bash
$ docker-compose run scheemer /bin/sh
$ docker-compose run scheemer rspec
$ docker-compose build scheemer
```

## Installation

Install the gem and add to the application's Gemfile by executing:

```bash
$ bundle add aion-dk/scheemer
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
$ gem install aion-dk/scheemer
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
