---
agent: docs-agent
description: "Write or update documentation for barrel_file_lints analyzer plugin"
name: "docs"
argument-hint: "target=<what-to-document> type=<readme|changelog|contributing>"
---

You are writing documentation using the docs-agent expertise. Create clear, accurate documentation following this Dart analyzer plugin project's standards.

## Context

Workspace: ${workspaceFolder}
Target: ${input:target:What to document? (rule, fix, or topic)}
Doc type: ${input:type:Documentation type (readme/changelog/contributing/auto)}
Focus: ${input:focus:Any specific aspects to emphasize? (optional)}

## Documentation Strategy

Apply your documentation expertise from #file:../agents/docs.agent.md with these requirements:

### Document Selection

**Auto-detect documentation type if not specified:**

- **README.md** for:

  - Project overview and installation
  - Rules documentation with examples
  - Quick fixes documentation
  - Configuration guide
  - Usage examples

- **CHANGELOG.md** for:

  - Version history using Conventional Commits
  - Grouped by type (Features, Bug Fixes, Breaking Changes, Documentation)
  - Semantic versioning
  - **Only user-facing changes** (exclude internal tooling, CI/CD, development workflows)

- **CONTRIBUTING.md** for:

  - Development setup
  - Testing guidelines (analyzer_testing patterns)
  - Code style (Dart 3.10+ features)
  - Pull request process
  - **Keep concise** - point to existing code patterns, avoid verbosity

- **example/example.md** for:

  - Usage examples with code snippets
  - Configuration examples

- **Dartdoc comments** (`lib/**/*.dart`) for:
  - Public API documentation using `///`
  - Class, method, and field descriptions
  - Code examples in doc comments
  - Parameter and return value documentation

### Documentation Requirements

1. **Code Examples**: Use real patterns from `lib/src/rules/` and `lib/src/fixes/` - verify with search tool
2. **Validation**: Run get_errors to check markdown linting before completion
3. **Accuracy**: Verify code examples compile with dart analyze
4. **Links**: Check all cross-references exist (no broken links)
5. **Structure**: Follow existing documentation patterns
6. **Examples**: Include ✅ Valid and ❌ Invalid import patterns for rules
7. **Updates**: Update "Last Updated" date to current date

### Validation Checklist

Before completing:

- [ ] No markdown lint warnings (get_errors)
- [ ] Code examples verified from actual codebase (lib/src/rules/, lib/src/fixes/)
- [ ] All file references exist
- [ ] Both naming conventions documented (feature_xxx/ and features/xxx/)
- [ ] Quick fix behavior documented for each rule
- [ ] CHANGELOG follows Conventional Commits format

## Output Format

Provide documentation with:

**Documentation Created/Updated** - List of files modified with brief description

**Validation Results** - Confirm all checks passed

**Cross-References** - Related docs that may need updates

**Next Steps** - Any follow-up documentation needed

## Example Usage

```
/docs target=avoid_internal_feature_imports type=readme
/docs target=lib/src/rules/avoid_internal_feature_imports.dart (add dartdoc)
/docs target=CHANGELOG
/docs target=CONTRIBUTING
/docs target=README
/docs target=example/example.md
```

## Related Files

- `.github/agents/docs.agent.md` - Documentation agent with detailed guidelines
- `.github/instructions/commits.instructions.md` - CHANGELOG format (Conventional Commits)
- `.github/copilot-instructions.md` - Project standards and patterns
- `README.md` - Main project documentation
- `CHANGELOG.md` - Version history
- `CONTRIBUTING.md` - Development guidelines

---

**Tip:** Use this prompt after implementing new rules or fixes to keep documentation synchronized with code.
