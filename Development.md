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

## Performance benchmarks

Run the constructor and parameter-reader microbenchmarks:

```bash
bundle exec ruby benchmark/performance.rb
```

The JSON output reports median wall-time throughput, process-CPU-time throughput,
and allocations per operation over five samples, with warmup and garbage collection
before each sample. CPU time excludes scheduling delays on shared machines. Constructor
cases cover flat, wrapped, and legacy modes; no defaults, supplied values, and
missing defaults; and small versus larger nested payloads. Reader cases run
50 times as many iterations as constructors to better measure their shorter operations.

Use `ITERATIONS` and an odd `SAMPLES` count to adjust the run. To compare a trusted
local checkout with the same dependencies, set `BASELINE_LIB` to that checkout's
absolute `lib` path. The script loads it in an isolated namespace and alternates
before/after samples within one process to reduce timing drift:

```bash
ITERATIONS=2000 SAMPLES=7 bundle exec ruby benchmark/performance.rb
BASELINE_LIB=/path/to/baseline/lib bundle exec ruby benchmark/performance.rb
```

## Docker

The Docker image installs the bundle inside the container and mounts the
repository at `/usr/src/app`:

```bash
docker-compose build scheemer
docker-compose run scheemer /bin/sh
docker-compose run scheemer rspec
```
