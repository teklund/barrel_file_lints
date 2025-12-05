# Barrel File Cycle Checker

A standalone CLI tool to detect circular dependencies between barrel files.

## Usage

After installing the package, run:

```bash
dart run barrel_file_lints:check_cycles
```

### Options

- `--lib-dir=<path>` or `-l <path>`: Specify the lib directory to analyze (default: `lib`)
- `--verbose` or `-v`: Show verbose output
- `--help` or `-h`: Show help message

### Examples

```bash
# Check cycles in default lib/ directory
dart run barrel_file_lints:check_cycles

# Check cycles in a specific directory
dart run barrel_file_lints:check_cycles --lib-dir=packages/my_package/lib

# Verbose output
dart run barrel_file_lints:check_cycles --verbose
```

## What it Detects

This tool detects **transitive circular dependencies** between barrel files, including complex cycles like:

```text
feature_a/a.dart → feature_b/b.dart → feature_c/c.dart → feature_a/a.dart
```

### Exit Codes

- `0`: No cycles found ✅
- `1`: Cycles detected ❌
- `2`: Error during analysis

## Example Output

When cycles are found:

```text
❌ Found 1 circular dependency:

Cycle 1:
  feature_auth/auth.dart
    ↓ exports
  feature_profile/profile.dart
    ↓ exports
  feature_settings/settings.dart
    ↓ exports back to feature_auth/auth.dart
```

When no cycles are found:

```text
✅ No circular dependencies found!
```

## Integration with CI/CD

Add this to your CI pipeline to prevent circular dependencies:

```yaml
# .github/workflows/ci.yml
- name: Check barrel file cycles
  run: dart run barrel_file_lints:check_cycles
```

## How It Works

1. Scans all barrel files (matching `feature_xxx/xxx.dart` or `features/xxx/xxx.dart`)
2. Builds a dependency graph from `export` directives
3. Uses depth-first search to detect cycles
4. Reports all cycles found

## Performance Note

This CLI tool is the **only** cycle detection method provided by this package. Previously, there was a real-time analyzer rule (`avoid_barrel_cycle`), but it was removed due to performance concerns (synchronous file I/O).

This CLI tool provides:

- **Comprehensive analysis**: Detects both immediate (A ↔ B) and transitive cycles (A → B → C → A)
- **Full project scanning**: Analyzes all barrel files at once
- **CI/CD integration**: Perfect for pipeline checks
- **Zero runtime overhead**: Runs on-demand, not during every analysis

Run this tool periodically or integrate it into your CI/CD pipeline for complete cycle detection!
