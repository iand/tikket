# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

See @README.md for usage documentation. Run `tk help` for command reference. Always update the README.md usage content when adding/changing commands and flags.

## Architecture

**Core script:** Single-file bash implementation (`ticket`, ~1850 lines). Uses awk for performant bulk operations on large ticket sets.

Key functions:
- `generate_prefix()` / `generate_id()` - Creates IDs from directory name prefix + random suffix
- `validate_slug()` - Checks `create --slug` values, which replace the random suffix
- `ticket_path()` - Resolves partial IDs to full file paths
- `yaml_field()` / `update_yaml_field()` / `remove_yaml_field()` - YAML frontmatter access.
  Updates use awk with values passed through `ENVIRON`, and only touch the frontmatter
- `set_status()` - The only place status changes; keeps `closed:` and `resolution:` in step
- `find_path()` - Path search over `deps` or `parent` edges; used to refuse cycles
- `acquire_lock()` / `release_lock()` - `mkdir` lock used by `claim`
- `current_user()` - `TK_ASSIGNEE`, else git user.name
- `array_contains()` / `array_remove()` - Exact-element operations on inline YAML arrays
  (`deps`, `links`). Use these rather than grep/sed so `nw-fix` never matches `nw-fix-login`
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
