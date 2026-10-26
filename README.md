# tikket

The git-backed issue tracker for AI agents. Rooted in the Unix Philosophy, `tk` is inspired by Joe
Armstrong's [Minimal Viable Program](https://joearms.github.io/published/2014-06-25-minimal-viable-program.html)
with additional quality of life features for managing and querying against complex issue
dependency graphs.

`tikket` started as a fork of [wedow/ticket](https://github.com/wedow/ticket) and has since
diverged. It keeps only the commands for managing tickets (the plugin system, the `edit`, `query`
and `migrate-beads` plugins, and the Homebrew/AUR packaging are gone) and adds commands for agent
workflows: `check`, `set`, `next`, `claim` and close resolutions. The ticket file format and the
`.tickets/` directory are unchanged, so existing tickets work as they are. The command is still
installed as `tk`.

`tk` was written as a full replacement for [beads](https://github.com/steveyegge/beads). It shares
many similar commands but without the need for keeping a SQLite file in sync or a rogue background
daemon mangling your changes.

Tickets are markdown files with YAML frontmatter in `.tickets/`. This allows AI agents to easily
search them for relevant content without dumping ten thousand character JSONL lines into their
context window.

Using ticket IDs as file names also allows IDEs to quickly navigate to the ticket for you. For
example, you might run `git log` in your terminal and see something like:

```
nw-5c46: add SSE connection management 
```

VS Code allows you to Ctrl+Click or Cmd+Click the ID and jump directly to the file to read the
details.

IDs are the project's prefix (see `tk init` below) plus a random 4-character suffix. Pass `--slug` to `create` to use a
meaningful suffix instead:

```
$ tk create "Fix login redirect" --slug fix-login
nw-fix-login
```

A slug uses lowercase letters, digits and single hyphens. `create` refuses an ID that already
exists.

## Install

**From source (auto-updates on git pull):**
```bash
git clone https://github.com/iand/tikket.git
cd tikket && ln -s "$PWD/tikket" ~/.local/bin/tk
```

**Or** just copy `tikket` to somewhere in your PATH, named `tk`.

Then, in each project:

```bash
tk init                # creates .tickets/ at the git root and records the ID prefix
tk init --prefix sf    # the same, choosing the prefix (also changes it on an existing project)
```

`init` uses `$TK_DIR` or `$TICKETS_DIR` instead when set, and works outside git by creating
`.tickets/` in the current directory. Without `init`, the first `tk create` creates `.tickets/` in
the current directory, which may be a subdirectory of the project.

Ticket IDs are `<prefix>-<suffix>`. The prefix is read from `.tickets/.prefix`, which `init`
writes; commit it so every clone and worktree generates the same IDs whatever its directory is
called. Without the file, the prefix is derived from the name of the directory that contains
`.tickets/` (`my-shop` gives `ms`, `plan` gives `pla`). For an existing project, run `tk init` (or
`tk init --prefix <current prefix>`) once to record it.

## Requirements

`tk` is a portable bash script requiring only coreutils, so it works out of the box on any POSIX
system with bash installed.

## Agent Setup

Add this line to your `CLAUDE.md` or `AGENTS.md`:

```
This project uses a CLI ticket system for task management. Run `tk help` when you need to use it.
```

Claude Opus picks it up naturally from there. Other models may need additional guidance.

### Working loop for agents

```bash
id=$(tk next | cut -d' ' -f1)       # highest-priority open ticket with deps resolved
tk claim "$id"                     # in_progress + assignee; fails if another agent has it
tk add-note "$id" "Found the cause in auth.go"
tk close "$id" -m "Fixed in PR 12"  # or: -r wontfix / -r duplicate
tk check                           # broken references or invalid fields; exits 1 if any
```

When several agents share one `.tickets/` directory, give each its own identity with
`TK_ASSIGNEE` (e.g. `TK_ASSIGNEE=agent-2`). It is used as the default assignee for `create`, the
claimant for `claim` and the author of notes. Without it, `git config user.name` is used.

`claim` holds a lock directory (`.tickets/<id>.lock`) while it checks and updates the ticket, so
concurrent claims have exactly one winner. Other commands do not take the lock. If a `tk` process is
killed while claiming, remove the lock directory by hand.

## Usage

```bash
tk - minimal ticket system with dependency tracking

Usage: tk <command> [args]

Commands:
  init [--prefix P]        Create .tickets/ at the git root (or current dir, or $TK_DIR)
                           and record the ID prefix in .tickets/.prefix
  create [title] [options] Create ticket, prints ID
    -d, --description      Description text
    --design               Design notes
    --acceptance           Acceptance criteria
    -t, --type             Type (bug|feature|task|epic|chore) [default: task]
    -p, --priority         Priority 0-4, 0=highest [default: 2]
    -a, --assignee         Assignee [default: $TK_ASSIGNEE or git user.name]
    --parent               Parent ticket ID
    --tags                 Comma-separated tags (e.g., --tags ui,backend,urgent)
    -s, --slug             Use slug instead of random suffix in ID (e.g., --slug fix-login)
  set <id> <field> <value> Set title|type|priority|assignee|parent|tags (empty clears)
  start <id>               Set status to in_progress
  claim <id> [-a X]        Start a ticket and assign it; fails if someone else has it
  close <id> [options]     Set status to closed (refuses if children are open)
    -m, --message          Add a note explaining the outcome
    -r, --resolution       done|wontfix|duplicate [default: done]
    -f, --force            Close even if children are open
  reopen <id>              Set status to open
  status <id> <status>     Update status (open|in_progress|closed)
  dep <id> <dep-id>        Add dependency (id depends on dep-id; refuses cycles)
  dep tree [--full] <id>   Show dependency tree (--full disables dedup)
  dep cycle                Find dependency cycles in open tickets
  undep <id> <dep-id>      Remove dependency
  link <id> <id> [id...]   Link tickets together (symmetric)
  unlink <id> <target-id>  Remove link between tickets
  ls|list [--status=X] [-a X] [-T X]   List tickets
  ready [-a X] [-T X] [--all]  List open tickets with deps resolved (--all adds in-progress)
  next [-a X] [-T X]       Show the single highest-priority ready ticket
  blocked [-a X] [-T X]    List open/in-progress tickets with unresolved deps
  closed [--limit=N] [-a X] [-T X] List recently closed tickets (default 20, newest first)
  show <id>                Display ticket
  add-note <id> [-a X] [text]  Append timestamped note (or pipe via stdin)
  check                    Report broken references and invalid fields; exits 1 if any

Tickets stored as markdown files in .tickets/
Searches parent directories for .tickets/ (override with TK_DIR or TICKETS_DIR env var)
Set TK_ASSIGNEE to give each agent its own identity for claim and notes
Supports partial ID matching (e.g., 'tk show 5c4' matches 'nw-5c46')
```

## Testing

The tests are written in the Behavior-Driven Development library
[behave](https://behave.readthedocs.io/en/latest/) and require Python.

If you have `uv` [installed](https://docs.astral.sh/uv/getting-started/installation/) simply:

```sh
make test
```

## License

MIT
