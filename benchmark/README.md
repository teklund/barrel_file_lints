# Performance Benchmarking

## Manual Performance Testing

### Setup
1. Create a test project with many features (50+)
2. Each feature should have:
   - Barrel file
   - 10+ internal files with imports
   - Cross-feature imports

### Measurement
```bash
# Time full analysis
time dart analyze --no-fatal-infos

# With verbose output to confirm plugin is active
dart analyze --verbose | grep barrel_file_lints

# Disable plugin for baseline
# Comment out plugin in analysis_options.yaml
time dart analyze --no-fatal-infos
```

### Expected Results
- Plugin overhead should be < 10% of total analysis time
- If > 20%, there's a performance problem

## Automated Benchmarking

### Using Dart's Benchmark Harness
```dart
import 'package:benchmark_harness/benchmark_harness.dart';

class FeatureExtractionBenchmark extends BenchmarkBase {
  FeatureExtractionBenchmark() : super('FeatureExtraction');
  
  static const paths = [
    'package:myapp/feature_auth/data/repository.dart',
    'package:myapp/features/profile/domain/entity.dart',
    // ... 100+ paths
  ];
  
  @override
  void run() {
    for (final path in paths) {
      extractFeature(path);
    }
  }
}

void main() {
  FeatureExtractionBenchmark().report();
}
```

## Profiling with DevTools

```bash
# Run analyzer with VM service
dart --observe analyze

# Open DevTools and connect
# Use CPU profiler to identify hot paths
```

## Performance Targets

- **Feature extraction**: < 1μs per call
- **Pattern matching**: < 5μs per import
- **Cycle detection**: Skip or defer to CLI tool
- **Total overhead**: < 10% of analysis time
