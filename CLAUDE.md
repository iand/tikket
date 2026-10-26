# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

See @README.md for usage documentation. Run `tk help` for command reference. Always update the README.md usage content when adding/changing commands and flags.

## Architecture

**Core script:** Single-file bash implementation (`ticket`, ~1300 lines). Uses awk for performant bulk operations on large ticket sets.

Key functions:
- `generate_id()` - Creates IDs from directory name prefix + random suffix
- `ticket_path()` - Resolves partial IDs to full file paths
- `yaml_field()` / `update_yaml_field()` - YAML frontmatter manipulation via sed
- `cmd_*()` - Command handlers
- `cmd_ready()`, `cmd_blocked()`, `cmd_ls()` - awk-based bulk listing with sorting

Dependencies: bash, sed, awk, find, grep.

Scope: this fork keeps only commands that manage tickets. There is no plugin system and no
packaging; new commands go directly in the core script.

## Testing

BDD tests using [Behave](https://behave.readthedocs.io/). Run with `make test` (requires `uv`).

- Feature files: `features/*.feature` - Gherkin scenarios covering all commands
- Step definitions: `features/steps/ticket_steps.py`
- CI runs tests on push to main and all PRs

When adding new commands or flags, add corresponding scenarios to the appropriate feature file.

## Changelog

Update CHANGELOG.md when committing notable changes:
- New commands, flags, bug fixes, behavior changes
- Add under appropriate heading (Added, Fixed, Changed, Removed)

Example:
```markdown
## [Unreleased]

### Added
- New `foo` command
```

### What Doesn't Need Logging
- Documentation-only changes
- CI/workflow changes (unless they affect user-facing behavior)
