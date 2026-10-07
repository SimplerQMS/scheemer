# frozen_string_literal: true

require "json"
require File.join(ENV.fetch("SCHEEMER_LIB", File.expand_path("../lib", __dir__)), "scheemer")

require_relative "workloads"

module PerformanceBenchmark
  extend self

  include PerformanceWorkloads

  def workloads(library)
    reads = lookup_workloads(library).transform_values { |operation| [operation, 50] }
    constructors = constructor_workloads(library).transform_values { |operation| [operation, 1] }

    reads.merge(constructors)
  end

  def measure(operations, iterations, samples)
    measurements_for(operations, iterations, samples).transform_values do |measurements|
      summarize(measurements, iterations, samples)
    end
  end

  def measurements_for(operations, iterations, samples)
    operations.each_value { |operation| 1000.times { operation.call } }
    measurements = operations.transform_values { [] }

    samples.times do |sample|
      ordered = sample.even? ? operations.to_a : operations.to_a.reverse
      ordered.each { |label, operation| measurements[label] << measure_sample(operation, iterations) }
    end

    measurements
  end

  def summarize(measurements, iterations, samples)
    {
      iterations:,
      samples:,
      ops_per_second: iterations / median(measurements.map { |sample| sample[:seconds] }),
      ops_per_cpu_second: iterations / median(measurements.map { |sample| sample[:cpu_seconds] }),
      allocations_per_op: median(measurements.map { |sample| sample[:allocations].fdiv(iterations) }),
    }
  end

  def measure_sample(operation, iterations)
    GC.start
    allocated = GC.stat(:total_allocated_objects)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    cpu_started = Process.clock_gettime(Process::CLOCK_PROCESS_CPUTIME_ID)
    iterations.times { operation.call }
    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
    cpu_elapsed = Process.clock_gettime(Process::CLOCK_PROCESS_CPUTIME_ID) - cpu_started

    { seconds: elapsed, cpu_seconds: cpu_elapsed, allocations: GC.stat(:total_allocated_objects) - allocated }
  end

  def median(values)
    values.sort.fetch(values.size / 2)
  end

  # Evaluate trusted local sources in a separate namespace so both versions can
  # be sampled alternately without redefining the current library's constants.
  def load_baseline(lib)
    namespace = Module.new
    sources = %w[errors extensions/string fallbacker params schema version].map { |name| "scheemer/#{name}.rb" }

    [*sources, "scheemer.rb"].each do |relative_path|
      path = File.join(lib, relative_path)
      source = File.readlines(path).reject { |line| line.start_with?("require_relative ") }.join
      namespace.module_eval(source, path)
    end

    namespace.const_get(:Scheemer)
  end

  def benchmark_libraries(libraries, iterations, samples)
    cases = libraries.transform_values { |library| workloads(library) }

    cases.fetch("after").to_h do |name, (_operation, multiplier)|
      operations = cases.transform_values { |library_cases| library_cases.fetch(name).first }
      [name, measure(operations, iterations * multiplier, samples)]
    end
  end

  def run
    iterations = Integer(ENV.fetch("ITERATIONS", "2000"))
    samples = Integer(ENV.fetch("SAMPLES", "5"))
    raise ArgumentError, "Use positive iterations and a positive odd sample count" unless
      iterations.positive? && samples.positive? && samples.odd?

    libraries = { "after" => Scheemer }
    libraries["before"] = load_baseline(ENV.fetch("BASELINE_LIB")) if ENV.key?("BASELINE_LIB")
    results = benchmark_libraries(libraries, iterations, samples)

    puts JSON.pretty_generate(ruby: RUBY_DESCRIPTION, results:)
  end
end

PerformanceBenchmark.run
