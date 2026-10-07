# Performance comparison

Baseline: `c3676da`. After: local lookup, fallback-scoping, and schema-key-name
refactorings. Measured on Linux x86_64 with Ruby 3.4.10, without YJIT.

Both versions ran in one process using the same workloads and dependencies.
Each operation had 1,000 warmup calls per version, followed by five samples with
alternating version order and garbage collection before every sample. Readers
ran 100,000 iterations per sample; constructors ran 2,000. GC remained enabled.
The table reports median wall-time throughput and median allocated objects per
operation. The JSON output also records process-CPU-time throughput.

Reader throughput improved in every measured case, with 39–78% fewer allocated
objects. Constructors allocated 17–19 fewer objects with fallbacks, or 15–20 fewer
without fallbacks. Constructor throughput was mixed (0.84–1.53×); these results do
not establish a uniform constructor speedup. Earlier separate-process runs had
substantial timing drift, so prefer repeated, interleaved comparisons before
making latency claims. These are microbenchmarks, not endpoint benchmarks.

Constructor names are `construct/mode/default-state/tag-count`. `none` has no
fallback declarations, `supplied` has defaults but caller-supplied values, and
`missing` exercises default insertion. Large cases contain 128 string tags;
their `tags` default is therefore not used, but other defaults may still apply.

| Workload | Before ops/s | After ops/s | Throughput ratio | Allocations/op |
| --- | ---: | ---: | ---: | ---: |
| `read/snake` | 233,519 | 847,136 | 3.63× | 27 → 6 |
| `read/camel` | 145,619 | 272,793 | 1.87× | 27 → 16 |
| `read/missing` | 184,095 | 308,383 | 1.68× | 23 → 13 |
| `read/method` | 203,982 | 270,500 | 1.33× | 28 → 17 |
| `read/fetch_nil` | 229,696 | 347,515 | 1.51× | 27 → 16 |
| `read/key_false` | 253,860 | 836,167 | 3.29× | 23 → 6 |
| `construct/flat/none/0` | 39,992 | 44,004 | 1.10× | 69 → 54 |
| `construct/flat/none/128` | 6,908 | 7,133 | 1.03× | 77 → 62 |
| `construct/flat/supplied/0` | 14,388 | 15,744 | 1.09× | 116 → 98 |
| `construct/flat/supplied/128` | 5,816 | 8,912 | 1.53× | 116 → 98 |
| `construct/flat/missing/0` | 14,393 | 14,079 | 0.98× | 126 → 108 |
| `construct/flat/missing/128` | 5,799 | 6,255 | 1.08× | 123 → 105 |
| `construct/wrapped/none/0` | 19,018 | 21,196 | 1.11× | 72 → 57 |
| `construct/wrapped/none/128` | 9,100 | 8,281 | 0.91× | 80 → 65 |
| `construct/wrapped/supplied/0` | 18,032 | 19,804 | 1.10× | 138 → 121 |
| `construct/wrapped/supplied/128` | 8,094 | 6,837 | 0.84× | 138 → 121 |
| `construct/wrapped/missing/0` | 14,302 | 18,890 | 1.32× | 148 → 131 |
| `construct/wrapped/missing/128` | 5,235 | 5,560 | 1.06× | 145 → 128 |
| `construct/legacy/none/0` | 19,192 | 20,606 | 1.07× | 78 → 58 |
| `construct/legacy/none/128` | 6,350 | 6,730 | 1.06× | 86 → 66 |
| `construct/legacy/supplied/0` | 11,686 | 12,901 | 1.10× | 131 → 112 |
| `construct/legacy/supplied/128` | 8,414 | 8,868 | 1.05× | 131 → 112 |
| `construct/legacy/missing/0` | 10,864 | 12,737 | 1.17× | 141 → 122 |
| `construct/legacy/missing/128` | 5,345 | 5,409 | 1.01× | 138 → 119 |

## Reproduce

With dependencies installed and a checkout of the baseline available:

```bash
BASELINE_LIB=/path/to/baseline/lib bundle exec ruby benchmark/performance.rb
```

This environment required a temporary external Gemfile adding `erb` to run
RSpec under Ruby 3.4. The same bundle was used for both benchmark versions;
the repository's Gemfile and lockfile were not changed.
