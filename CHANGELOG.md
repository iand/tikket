# Changelog

## [Unreleased]

Fork of wedow/ticket trimmed to ticket management only. Changes are relative to 0.3.2.

### Renamed
- Project renamed to `tikket`; the script is now `tikket`. The `tk` command name, `.tickets/`
  directory, ticket file format and `TICKETS_DIR` variable are unchanged.

### Added
- `-s, --slug` flag for `create` to use a meaningful ID suffix instead of a random one
- `create` refuses to overwrite an existing ticket ID
- `check` command: reports missing or self references, one-sided links, parent cycles, invalid
  status/type/priority/resolution, id/filename mismatches and malformed frontmatter; exits 1 if any
- `set <id> <field> <value>` for title, type, priority, assignee, parent and tags
- `next` command: the single highest-priority ready ticket
- `claim` command: sets in_progress and assignee under a lock; fails if another assignee has it
- `close -m/--message` adds a note, `close -r/--resolution done|wontfix|duplicate` records the outcome
- `closed:` timestamp and `resolution:` field written on close and removed on reopen/start
- `add-note -a/--author`; notes record their author
- `TK_ASSIGNEE` environment variable for the default assignee, claimant and note author

### Changed
- `ready` lists open tickets only; `--all` includes in-progress tickets as before
- `closed` sorts by the `closed:` timestamp instead of file mtime, and filters before applying the
  limit (it previously looked at only the 100 most recently modified files); shows the resolution
- `close` and `status <id> closed` refuse a ticket with open children unless `close --force`
- `dep` refuses a dependency on itself or one that would create a cycle
- `create` validates `--type` and `--priority`
- Frontmatter updates only touch the frontmatter and accept any characters in values

### Fixed
- `dep`, `undep` and `unlink` match whole IDs, so an ID that is a substring of another (e.g.
  `nw-fix` and `nw-fix-login`) no longer causes false "already exists" results or corrupts arrays
- `dep tree` prefers an exact ID match over longer IDs containing it

### Removed
- `edit` command
- `query` command (and the `jq` dependency)
- `migrate-beads` command
- `--external-ref` flag for `create`
- `TICKET_PAGER` / `PAGER` support for `show`
- `closed` no longer lists tickets with the non-standard status `done`
- ripgrep preference; plain `grep` is always used
- Homebrew and AUR packaging, and the release workflow

## [0.3.2] - 2026-02-03

### Fixed
- Ticket ID lookup now trims leading/trailing whitespace (fixes issue with AI agents passing extra spaces)

## [0.3.1] - 2026-01-28

### Added
- `list` command alias for `ls`
- `TICKET_PAGER` environment variable for `show` command (only when stdout is a TTY; falls back to `PAGER`)

### Changed
- Walk parent directories to find `.tickets/` directory, enabling commands from any subdirectory
- Ticket ID suffix now uses full alphanumeric (a-z0-9) instead of hex for increased entropy

### Fixed
- `dep` command now resolves partial IDs for the dependency argument
- `undep` command now resolves partial IDs and validates dependency exists
- `unlink` command now resolves partial IDs for both arguments
- `create --parent` now validates and resolves parent ticket ID
- `generate_id` now uses 3-char prefix for single-segment directory names (e.g., "plan" → "pla" instead of "p")

## [0.3.0] - 2026-01-18

### Added
- Support `TICKETS_DIR` environment variable for custom tickets directory location
- `dep cycle` command to detect dependency cycles in open tickets
- `add-note` command for appending timestamped notes to tickets
- `-a, --assignee` filter flag for `ls`, `ready`, `blocked`, and `closed` commands
- `--tags` flag for `create` command to add comma-separated tags
- `-T, --tag` filter flag for `ls`, `ready`, `blocked`, and `closed` commands

## [0.2.0] - 2026-01-04

### Added
- `--parent` flag for `create` command to set parent ticket
- `link`/`unlink` commands for symmetric ticket relationships
- `show` command displays parent title and linked tickets
- `migrate-beads` now imports parent-child and related dependencies

## [0.1.1] - 2026-01-02

### Fixed
- `edit` command no longer hangs when run in non-TTY environments

## [0.1.0] - 2026-01-02

Initial release.
