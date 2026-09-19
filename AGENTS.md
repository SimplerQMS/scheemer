# AGENTS.md

## Project shape

- This is a Ruby gem named `scheemer`; the gemspec requires Ruby `>= 3.1` and the library entrypoint is `lib/scheemer.rb`.
- `Scheemer::DSL` combines `Scheemer::Schema::DSL` (Dry Schema validation) with `Scheemer::Params::DSL` (camelCase/snake_case accessors and missing-value fallbacks).
- The custom `:uuid_v7` type is registered in `lib/scheemer/schema.rb`; bang validation raises `Scheemer::InvalidSchemaError`.
- Runtime code is under `lib/`; RSpec coverage is under `spec/` with matching component specs. There are no generated sources or external services required by the test suite.

## Setup and verification

- Install dependencies with `bin/setup` (equivalent to `bundle install`) before running project commands.
- Run `bundle exec rake` for the canonical full check. The Rakefile runs the RSpec suite first, then RuboCop; CircleCI uses this same command.
- Run a focused test with `bundle exec rspec spec/scheemer/params_spec.rb` or `bundle exec rspec path/to/spec.rb:LINE`.
- Run focused lint with `bundle exec rubocop path/to/file.rb`; lint settings are in `.rubocop.yml` and target Ruby 3.1.
