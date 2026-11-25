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
system with bash installed. The optional `browse` command also needs fzf.

## Browsing tickets

`tk browse` opens the tickets in [fzf](https://github.com/junegunn/fzf), which is the only command
that needs it. Epics come first with their children indented beneath them, then tickets with no
parent; siblings are ordered by priority, and a parent shows its closed/total child count. The
view starts on unfinished tickets (open and in_progress); `--status=X` starts on another status
or a comma-separated list of them, and `--status=` on all tickets. Typing filters the list by
text, and the preview pane shows `tk show` for the selected ticket.

| Key                   | Action                                                       |
|-----------------------|--------------------------------------------------------------|
| alt-u                 | Show unfinished tickets (open and in_progress)               |
| alt-a/o/i/c           | Show all, open, in_progress or closed tickets                |
| enter                 | Read the ticket in `$PAGER` (default `less`)                 |
| ctrl-o                | Move the preview between the right side and the bottom       |
| ctrl-/                | Hide or show the preview                                     |
| shift-up / shift-down | Scroll the preview                                           |
| esc                   | Quit                                                         |

With a status filter, parents that do not match are still listed (dimmed) so their matching
children keep their place in the tree. `tk browse --print` writes the list to stdout without fzf.

## Agent Setup

Add this line to your `CLAUDE.md` or `AGENTS.md`:

```
This project uses a CLI ticket system for task management. Run `tk help` when you need to use it.
```

Claude Opus picks it up naturally from there. Other models may need additional guidance.

### Working loop for agents

`tk help` includes the working conventions as well as the commands: resume your own work first,
claim before starting, leave notes, close with the outcome, file follow-up work as new tickets,
and how to lay out an epic. Agents run it before using tk, so it is the place to change if you
want them to work differently.

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
    -s, --slug             Use slug instead of random suffix in ID; the prefix is added
                           automatically (e.g., --slug fix-login)
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
  ls|list [--status=X] [filters]  List tickets
  ready [filters] [--all]  List open tickets with deps resolved (--all adds in-progress)
                           Sorted by priority; a ticket takes the priority of any unclosed
                           ticket waiting on it, shown as [P2→P1]
  next [filters]           Show the single highest-priority ready ticket
  blocked [filters]        List open/in-progress tickets with unresolved deps
  closed [--limit=N] [filters]  List recently closed tickets (default 20, newest first)
    Filters for ls, ready, next, blocked and closed (exact match, one value each):
    -a, --assignee=X       Assigned to X
    -T, --tag=X            Has tag X
    -t, --type=X           Type is X
    -p, --priority=N       Priority is N (ready and next use the inherited priority)
  show <id>                Display ticket
  add-note <id> [-a X] [text]  Append timestamped note (or pipe via stdin)
  check                    Report broken references and invalid fields; exits 1 if any
  browse [--status=X] [--print]  Browse tickets grouped by parent in fzf, with a preview
                           (X may be a comma list; starts on open,in_progress, --status=
                           for all. --print writes the list to stdout instead; for humans,
                           not agents)

Working through tickets:
  1. Finish your own work first: tk ls --status=in_progress -a <you>
     (ready and next leave out in-progress tickets, including yours)
  2. Otherwise take tk next, then read it with tk show <id>. Leave in-progress
     tickets assigned to others alone.
  3. tk claim <id> before starting. With several agents in one repo, set
     TK_ASSIGNEE=<your name> on every call, or you all share git user.name.
  4. tk add-note <id> "..." for causes found, decisions and rejected approaches.
     If you stop early, leave it in progress with a note saying where you got to.
  5. tk close <id> -m "what changed, how it was verified". If the work was dropped:
     -r wontfix or -r duplicate with the reason. Close children before parents;
     --force only if the user asks for it.

Work noticed along the way: file it and carry on, rather than fixing it in passing
  tk create "..." -t bug -d "Found while working on <id>: ..."
  Name the new ticket in <id>'s close message. If <id> can't be finished without
  it, tk dep <id> <new-id>.

Planning a feature:
  - An epic (-t epic) and children (--parent <epic>), each with --acceptance
    criteria and a --slug for a readable ID
  - Order goes in dependencies, not prose: tk dep A B means A waits for B
  - Make the epic depend on its children, so tk next hands out the children at the
    epic's priority rather than the epic itself
  - Check: tk dep tree <epic>, then tk next returns real work and tk check is clean

Change fields with set and the status commands rather than editing frontmatter.
tk never runs git; ticket files are committed like any other change.

Tickets stored as markdown files in .tickets/
Searches parent directories for .tickets/ (override with TK_DIR or TICKETS_DIR env var)
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
