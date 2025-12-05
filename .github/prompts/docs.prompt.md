---
agent: docs-agent
description: 'Write or update documentation following Flutter project standards'
name: 'docs'
argument-hint: 'target=<what-to-document> type=<instruction|technical|readme|changelog>'
---

You are writing documentation using the docs-agent expertise. Create clear, accurate documentation following this Flutter project's documentation standards.

## Context

Workspace: ${workspaceFolder}
Target: ${input:target:What to document? (feature, file, or topic)}
Doc type: ${input:type:Documentation type (instruction/technical/readme/changelog/auto)}
Focus: ${input:focus:Any specific aspects to emphasize? (optional)}

## Documentation Strategy

Apply your documentation expertise from #file:../agents/docs.agent.md with these requirements:

### Document Selection

**Auto-detect documentation type if not specified:**

- **Instruction files** (`.github/instructions/*.instructions.md`) for:
  - Code patterns and conventions
  - AI-assisted development guidelines
  - Feature-specific best practices
  - Testing, architecture, UI patterns

- **Technical docs** (`docs/**/*.md`) for:
  - Architecture explanations
  - Setup and configuration guides
  - Testing strategies
  - Troubleshooting and fixes

- **README files** for:
  - Project overview and quick start
  - Feature documentation index
  - Command reference tables

- **CHANGELOG** (`CHANGELOG.md`) for:
  - Version history using Conventional Commits
  - Grouped by type (Features, Bug Fixes, etc.)

### Documentation Requirements

1. **Code Examples**: Use real patterns from `lib/` - verify with semantic_search and read_file
2. **Validation**: Run get_errors to check markdown linting before completion
3. **Accuracy**: Verify code examples compile with flutter analyze
4. **Links**: Check all cross-references with file_search (no broken links)
5. **Structure**: Follow patterns from existing docs in same category
6. **Examples**: Include ✅ Good and ❌ Bad patterns for instruction files
7. **Updates**: Update "Last Updated" date and relevant index files

### Validation Checklist

Before completing:

- [ ] No markdown lint warnings (get_errors)
- [ ] Code examples verified from actual codebase
- [ ] All links checked and valid
- [ ] Index files updated (INSTRUCTIONS.md, AGENTS.md, docs/README.md)
- [ ] "Last Updated" date current
- [ ] Follows template for doc type

## Output Format

Provide documentation with:

**Documentation Created/Updated** - List of files modified with brief description

**Validation Results** - Confirm all checks passed

**Cross-References** - Related docs that may need updates

**Next Steps** - Any follow-up documentation needed

## Example Usage

```
/docs target=feature_auth type=instruction
/docs target=analytics patterns
/docs target=testing-strategy type=technical
/docs target=CHANGELOG
/docs target=docs/architecture/state-management.md
```

## Related Files

- `.github/instructions/docs.instructions.md` - Technical documentation patterns
- `.github/instructions/instructions.instructions.md` - Instruction file guidelines
- `.github/instructions/readme.instructions.md` - README patterns
- `.github/instructions/commits.instructions.md` - CHANGELOG format (Conventional Commits)

---

**Tip:** Use this prompt after implementing new features or making architectural changes to keep documentation synchronized with code.
