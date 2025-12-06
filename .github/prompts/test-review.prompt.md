---
agent: test-agent
description: "Review analyzer plugin tests using analyzer_testing framework"
name: "test-review"
argument-hint: "scope=<test-file-or-directory>"
---

# Test Review

Conduct a focused review of analyzer plugin test files. Analyze test quality, coverage, and adherence to analyzer_testing framework best practices.

## Context

Workspace: ${workspaceFolder}
Test scope: ${input:scope:What tests to review? (file path, directory, or leave empty for current file)}
Focus area: ${input:focus:Any specific concern? (coverage, rule behavior, quick fixes, etc.)}

## Review Approach

Apply your testing expertise from #file:../agents/test.agent.md with a **quick, focused approach**:

- Check analyzer_testing framework usage
- Verify both naming conventions tested (`feature_xxx/` and `features/xxx/`)
- Validate test structure and patterns
- Assess rule coverage completeness
- Verify quick fix functionality

## Test Quality Checklist

### ✅ Test Framework Usage

- [ ] Uses `analyzer_testing` package correctly
- [ ] Extends `AnalysisRuleTest` base class
- [ ] Uses `test_reflective_loader` for test discovery (`defineReflectiveSuite`, `defineReflectiveTests`)
- [ ] Proper `@reflectiveTest` annotation on test class
- [ ] Correct `setUp()` with rule initialization
- [ ] Uses `newFile()` to create test project files

### ✅ Test File Structure

- [ ] Descriptive test names following pattern: `test_scenario_variant()`
- [ ] Documentation comment at top: `/// Tests for [rule_name] rule`
- [ ] Comment explaining test organization (valid/invalid/coverage sections)
- [ ] Tests grouped by valid cases, invalid cases, edge cases
- [ ] One behavior per test method
- [ ] Follows naming: `*_test.dart` (not `*_unit_test.dart`)

### ✅ Naming Convention Coverage

- [ ] Tests `feature_xxx/` underscore pattern
- [ ] Tests `features/xxx/` slash pattern
- [ ] Both patterns tested for each rule behavior
- [ ] Examples: `test_barrelImport_underscore()` and `test_barrelImport_slash()`

### ✅ Test Cases Coverage

**Valid cases (no diagnostics):**

- [ ] Barrel file imports tested
- [ ] Same-feature imports tested
- [ ] Test file exclusions verified
- [ ] Relative imports within same feature

**Invalid cases (diagnostics expected):**

- [ ] Internal directory imports (`/data/`, `/ui/`, `/domain/`, `/presentation/`)
- [ ] Cross-feature violations
- [ ] All internal directory types covered
- [ ] Deep nesting scenarios

**Edge cases:**

- [ ] Test files excluded (`test/`, `*_test.dart`)
- [ ] Relative imports (`../`, `../../`)
- [ ] Same feature at different depths
- [ ] Package vs relative imports

### ✅ Assertion Quality

- [ ] Uses `assertNoDiagnosticsInFile()` for valid cases
- [ ] Uses `assertDiagnostics()` with precise offset/length for invalid cases
- [ ] Diagnostic messages include helpful context
- [ ] Error codes match rule's LintCode

### ✅ Quick Fix Tests

- [ ] Tests fix registration with rule
- [ ] Uses `assertHasFix()` to verify code transformation
- [ ] Tests fix produces valid, compilable code
- [ ] Tests both package and relative import fixes
- [ ] Verifies fix handles edge cases

## Output Format

Provide a concise review with:

**Quick Summary** - Overall test quality assessment

**❌ Issues Found** - Specific problems with file paths and line numbers

**💡 Improvements** - Suggestions to enhance test quality

**✅ Good Practices** - What's done well

**📊 Coverage Assessment** - What scenarios are covered/missing

**Approved** - Yes/No with brief reasoning

Keep the review focused and actionable. If tests look good, say so clearly!

## Common Test Anti-Patterns to Flag

**Avoid:**

- ❌ Vague test names: `test_import()`, `test_case1()`
- ❌ Not testing both naming conventions (`feature_xxx/` and `features/xxx/`)
- ❌ Missing valid cases (only testing violations)
- ❌ Missing edge cases (test files, relative imports, deep nesting)
- ❌ Wrong diagnostic offsets/lengths in `assertDiagnostics()`
- ❌ Not using `newFile()` to set up test files
- ❌ Forgetting `@reflectiveTest` annotation
- ❌ Not extending `AnalysisRuleTest`
- ❌ Missing quick fix tests for rules with fixes
- ❌ Testing only package imports, not relative imports

**Prefer:**

- ✅ Descriptive names: `test_barrelFileImport_underscore()`, `test_internalDataImport_violation()`
- ✅ Both `feature_xxx/` and `features/xxx/` patterns tested
- ✅ Valid cases with `assertNoDiagnosticsInFile()`
- ✅ Invalid cases with `assertDiagnostics()` and precise offsets
- ✅ Edge case coverage (test files, relative imports, same feature)
- ✅ Quick fix tests with `assertHasFix()` showing before/after
- ✅ Clear test file setup with `newFile()`
- ✅ Proper `setUp()` with rule initialization
- ✅ Test both import types (package and relative)
- ✅ Document test organization at file top

## Example Usage

```bash
/test-review
/test-review scope=test/
/test-review scope=test/avoid_internal_feature_imports_test.dart
/test-review focus=naming conventions
/test-review focus=quick fixes
/test-review focus=edge cases
```
