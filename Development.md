# Development

## Setup

Install the bundled dependencies before running project commands:

```bash
bundle install
```

## Verification

Run the full project check:

```bash
bundle exec rake
```

The default Rake task runs RSpec first and RuboCop second. To run an individual
suite or focused check:

```bash
bundle exec rspec
bundle exec rspec spec/scheemer/params_spec.rb
bundle exec rspec spec/scheemer/params_spec.rb:56
bundle exec rubocop
bundle exec rubocop lib/scheemer/params.rb
```

## Docker

The Docker image installs the bundle inside the container and mounts the
repository at `/usr/src/app`:

```bash
docker-compose build scheemer
docker-compose run scheemer /bin/sh
docker-compose run scheemer rspec
```
