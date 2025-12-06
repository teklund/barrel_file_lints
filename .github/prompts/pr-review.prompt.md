---
name: pr-review
description: Comprehensive pre-PR review for Dart analyzer plugin changes
agent: code-review-agent
argument-hint: "branch=<branch-name> focus=<area>"
---

# Pre-PR Review

Conduct a thorough pre-PR review for this Dart analyzer plugin project. Analyze the current branch against `master` and provide actionable feedback on readiness for Pull Request.

## Context

Workspace: ${workspaceFolder}
Review branch: ${input:branch:Branch name (leave empty for current branch)}
Target branch: master
Focus area: ${input:focus:Specific area to emphasize? (leave empty for comprehensive)}

## Review Approach

Apply expertise from #file:../agents/code-review.agent.md with these additional pre-PR checks:

### Pre-PR Checklist

1. **Git Status & Commits**

   - Run `git diff master...HEAD` to see all changes between branches
   - Check working tree is clean (no uncommitted changes)
   - Check all changes are committed
   - Suggest PR title following Conventional Commits format
   - Verify no merge conflicts with `git merge-base master HEAD`
   - **Note:** Squash merge strategy - no need for commit cleanup

2. **Code Quality**

   - Run `dart analyze --fatal-infos` (must pass with zero warnings)
   - Run `dart test` to verify all tests pass
   - Check for TODO/FIXME comments in changed files
   - Verify null checks on AST node properties
   - Confirm regex patterns are static (not recompiled)

3. **Testing Coverage**

   - Verify both `feature_xxx/` and `features/xxx/` patterns tested
   - Check valid and invalid test cases exist
   - Ensure edge cases covered (test files, relative imports)
   - Confirm quick fix tests verify code transformation

4. **Documentation**

   - Verify README updated if rules/fixes changed
   - Check CHANGELOG.md follows Conventional Commits format
   - Confirm code examples compile
   - Verify both naming conventions documented

5. **Dependencies**
   - Check `pubspec.yaml` changes are necessary
   - Verify no unnecessary dependencies added
   - Confirm analyzer package version matches Dart SDK

## Required Actions

Execute these steps before providing review:

1. Run `git diff master...HEAD --name-only` to list all changed files
2. Run `git diff master...HEAD` to see full diff between branches
3. Check working tree is clean (no uncommitted changes)
4. Analyze changed files from the diff
5. Run `dart analyze --fatal-infos` and report errors
6. Run `dart test` to verify all tests pass
7. Search for TODO/FIXME comments in changed files
8. Review against code-review-agent standards:
   - Null safety on AST nodes
   - Static regex patterns
   - Test coverage (both naming conventions)
   - Quick fix correctness
   - Error message quality
9. Suggest PR title in Conventional Commits format

## Output Format

Provide review in this structure:

### Executive Summary

Overall status: ✅ Ready | ❌ Not Ready | ⚠️ Ready with Recommendations

### Strengths

What's implemented well

### Blocking Issues (Must Fix)

Critical issues with file paths and line numbers

### Recommendations (Non-Blocking)

Quality improvements to consider

### Suggested PR Title

Use Conventional Commits format: `type(scope): description`

Examples:

- `feat(rules): add avoid_self_barrel_import rule`
- `fix(fixes): handle edge case in replace_with_barrel_import`
- `docs: update README with configuration examples`
- `test: add coverage for relative imports`

### Pre-Merge Checklist

- [ ] `dart analyze --fatal-infos` passes
- [ ] All tests pass
- [ ] CHANGELOG.md updated
- [ ] README updated (if applicable)
- [ ] Both naming conventions tested

### Next Steps

Specific actions needed before merge

---

Keep review factual, specific, and actionable with file paths and line numbers.

## Example Usage

```
/pr-review
/pr-review branch=feature/avoid-self-import
/pr-review focus=performance
/pr-review branch=fix/null-safety focus=correctness
```
