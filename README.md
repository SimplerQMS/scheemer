# Scheemer

Scheemer uses [Dry::Schema](https://github.com/dry-rb/dry-schema) to
enable us to write consistent looking structural parameter validation
and data accessing on our services.

## Usage

### Endpoint parameter objects

`Scheemer::DSL` combines Dry Schema validation with convenient access to the
validated parameters. Define the shape that the endpoint actually receives,
then choose whether the validated payload is flat or wrapped.

#### Flat parameters

Use `:flat` for endpoints whose request parameters are not nested under a
resource name:

```ruby
class IndexParams
  extend Scheemer::DSL

  params_mode :flat

  schema do
    optional(:status).filled(:string)
    optional(:page).filled(:integer)
  end
end

params = IndexParams.new({ status: "open", page: 2 })
params[:status] # => "open"
params.page      # => 2
params.to_h      # => { "status" => "open", "page" => 2 }
```

When the endpoint only needs the normalized hash, use `.call` instead of
keeping the parameter object:

```ruby
attributes = IndexParams.call({ status: "open", page: 2 })
# => { "status" => "open", "page" => 2 }
```

#### Wrapped parameters

Use `:wrapped` when the request follows the usual resource convention. The
root must be named explicitly, so adding another top-level field cannot change
which data is exposed by the object:

```ruby
class CreateUserParams
  extend Scheemer::DSL

  params_mode :wrapped, root: :user

  schema do
    required(:user).hash do
      required(:emailAddress).filled(:string)
      optional(:displayName).filled(:string)
    end
  end
end

params = CreateUserParams.new(
  { user: { emailAddress: "ada@example.com", displayName: "Ada" } }
)

params.email_address # => "ada@example.com"
params[:displayName] # => "Ada"
params.to_h          # => { "email_address" => "ada@example.com",
                     #      "display_name" => "Ada" }
```

Classes without `params_mode` retain the legacy behavior of exposing the first
validated top-level value. New classes should prefer an explicit mode.

### Access and normalization

Top-level keys can be accessed with methods, strings, or symbols. Snake case
and camel case spellings are interchangeable:

```ruby
params.email_address       # => "ada@example.com"
params[:email_address]     # => "ada@example.com"
params["emailAddress"]     # => "ada@example.com"
params.fetch(:email_address) # => "ada@example.com"
params.key?("emailAddress")  # => true
params.values_at(:email_address, :display_name)
# => ["ada@example.com", "Ada"]
```

`[]` returns `nil` for a missing key. `fetch` raises `KeyError` unless a
default or block is provided:

```ruby
params[:timezone]                  # => nil
params.fetch(:timezone, "UTC")     # => "UTC"
params.fetch(:timezone) { "UTC" }  # => "UTC"
```

`Params` includes `Enumerable`, so collection methods operate on the
underlying hash or array. It also supports `dig`, `empty?`, `size`, `length`,
`to_h`, and `to_hash`:

```ruby
params.size     # => 2
params.empty?   # => false
params.to_hash  # => same normalized, indifferent-access hash as to_h
params.map(&:to_a)
```

`to_h` returns an `ActiveSupport::HashWithIndifferentAccess`, so string and
symbol keys can be used interchangeably. Nested hashes also have indifferent
access, although their key spelling is not converted to snake case:

```ruby
result = params.to_h
result[:email_address] == result["email_address"] # => true
result[:profile]["displayName"]                   # => "Ada"
```

Key normalization applies only to the top-level `Params` object. Nested hashes
also have indifferent access, but their keys retain the spelling in the
validated data:

```ruby
params.dig(:profile, :displayName) # nested lookup uses the hash's actual key
```

### Defaults and validation context

`on_missing` fills a value before the validated payload is exposed. This is
useful for endpoint defaults:

```ruby
class SearchParams
  extend Scheemer::DSL

  params_mode :flat

  schema do
    optional(:page).filled(:integer)
    optional(:query).filled(:string)
  end

  on_missing path: "page", fallback_to: 1
end

SearchParams.call({})
# => { "page" => 1 }
```

Extra constructor data is available to custom validation through `validate!`:

```ruby
class UpdateUserParams
  extend Scheemer::DSL

  params_mode :flat

  schema do
    required(:email).filled(:string)
  end

  def validate!(data)
    raise "not allowed" unless data[:current_user].admin?
  end
end

UpdateUserParams.new(
  { email: "ada@example.com" },
  { current_user: current_user }
)
```

Invalid payloads raise `Scheemer::InvalidSchemaError` from `new` and `.call`.

### Standalone modules

Use `Scheemer::Params::DSL` when key translation is needed without schema
validation:

```ruby
class RawParams
  extend Scheemer::Params::DSL
end

RawParams.new({ someValue: "testing" }).some_value # => "testing"
```

Use `Scheemer::Schema::DSL` when only validation is needed:

```ruby
class UserSchema
  extend Scheemer::Schema::DSL

  schema do
    required(:name).filled(:string)
  end
end

UserSchema.validate!({ name: "Ada" })
```

## Development

See [Development.md](Development.md) for setup, test, lint, and Docker
commands.

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
