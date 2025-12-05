---
agent: test-agent
description: 'Quick review of test files for quality and best practices'
name: 'test-review'
argument-hint: 'scope=<test-file-or-directory>'
---

# Test Review

You are reviewing test code using the test-agent expertise. Analyze test files for quality, coverage, and adherence to Flutter testing best practices.

## Context

Workspace: ${workspaceFolder}
Test scope: ${input:scope:What tests to review? (file path, directory, or leave empty for current file)}
Focus area: ${input:focus:Any specific concern? (coverage, mocking, assertions, etc.)}

## Review Approach

Apply your testing expertise from #file:../agents/test.agent.md with a **quick, focused approach**:

- Prioritize critical test quality issues
- Check test structure and patterns
- Verify mocking strategy
- Assess coverage completeness
- Validate assertion quality

## Test Quality Checklist

### ✅ Structure & Organization

- [ ] Descriptive test names (behavior-driven, not implementation)
- [ ] Proper use of `group()` for logical organization
- [ ] Follows naming conventions (`*_unit_test.dart`, `*_widget_test.dart`, etc.)
- [ ] Mirrors `lib/` directory structure
- [ ] One behavior per test (single responsibility)

### ✅ Test Independence

- [ ] No shared state between tests
- [ ] Proper `setUp()` and `tearDown()` usage
- [ ] Each test can run independently
- [ ] No test order dependencies
- [ ] Clean initialization for each test

### ✅ Mocking Strategy

- [ ] Uses Mocktail for mocking
- [ ] Mocks external dependencies (services, APIs, repos)
- [ ] Doesn't mock pure functions or data classes
- [ ] Proper mock setup with `when()` and `thenAnswer()`
- [ ] Verifies interactions with `verify()` when needed

### ✅ Assertions & Coverage

- [ ] Tests happy path scenarios
- [ ] Tests error cases and exceptions
- [ ] Tests edge cases and boundaries
- [ ] Tests null safety scenarios
- [ ] Clear, meaningful assertions
- [ ] Uses appropriate matchers (`expect()`, `throwsA()`, etc.)

### ✅ Async Handling

- [ ] Proper `async`/`await` usage
- [ ] No missing awaits (causes flaky tests)
- [ ] Correct async stub setup with `thenAnswer((_) async => ...)`
- [ ] Handles Future/Stream testing correctly

### ✅ Test-Specific Issues

**Unit Tests:**

- [ ] Tests business logic, not implementation details
- [ ] Isolates code under test
- [ ] Fast execution (no real I/O)

**Widget Tests:**

- [ ] Uses `pumpWidget()` properly
- [ ] Mocks `AppLocalizations`
- [ ] Uses appropriate finders (`find.byKey()`, `find.text()`)
- [ ] Tests user interactions (`tap()`, `enterText()`)
- [ ] Verifies UI state changes

**Golden Tests:**

- [ ] Uses Alchemist patterns
- [ ] Tests multiple states/themes
- [ ] Commits CI goldens only (`goldens/ci/`)
- [ ] Descriptive scenario names

**Integration Tests:**

- [ ] Uses Patrol Screen Object Model
- [ ] Tagged with `'e2e'` for main workflows
- [ ] Tests complete user journeys
- [ ] Proper screen navigation

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

- ❌ Vague test names: `test('works')`, `test('should return data')`
- ❌ Multiple unrelated assertions per test
- ❌ Testing implementation details instead of behavior
- ❌ Shared mutable state between tests
- ❌ Over-mocking (mocking pure functions, data classes)
- ❌ Missing error case tests
- ❌ Brittle finders in widget tests (prefer keys)
- ❌ Missing `await` in async tests
- ❌ Testing generated code (`*.g.dart`, `*.freezed.dart`)
- ❌ Not using `setUp()` for repetitive initialization

**Prefer:**

- ✅ Behavior-driven names: `test('returns user data when API call succeeds')`
- ✅ One assertion per concept
- ✅ Test behavior, not implementation
- ✅ Isolated test setup in `setUp()`
- ✅ Mock at boundaries (services, APIs)
- ✅ Test both success and failure paths
- ✅ Use `find.byKey()` with unique keys
- ✅ Always `await` async operations
- ✅ Test source code, not generated code
- ✅ Clear arrange-act-assert structure

## Example Usage

```bash
/test-review
/test-review scope=test/feature_auth/
/test-review scope=test/feature_ticket_purchase/data/purchase_service_unit_test.dart
/test-review focus=mocking strategy
/test-review focus=coverage gaps
```
