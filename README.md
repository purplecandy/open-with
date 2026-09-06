# open-with

Set the default macOS application for file types, from the terminal.

```sh
open-with md json -w Zed      # Markdown and JSON now open in Zed
open-with                     # pick types, then pick an app
open-with -l                  # what opens what right now?
open-with history             # everything it has changed
open-with undo last           # put it back
open-with --doctor            # clean up ghost app registrations
```

No Homebrew, no `duti`, no compiler, no `sudo`. One file, ~700 lines of bash.

## Why

macOS quietly registers every app it lays eyes on — including copies sitting
inside a mounted `.dmg`, an unzip temp folder, or an old versioned directory.
When one of those wins the race to become the default handler and then
disappears, you get:

> The application cannot be opened because it has been moved to the Trash.

…for an app that is plainly sitting in `/Applications`. It is not Gatekeeper,
and reinstalling does not help, because the broken record outlives the app.

`open-with` clears the stale records that shadow your app before it sets
anything, so the change actually takes.

`--doctor` sweeps up the rest. On the machine this was written on, a first run
found **296** of them — 55 pointing into disk images that were unmounted months
ago.

```
$ open-with --doctor
Found 296 registration(s) pointing at apps that no longer exist:

  [unmounted disk image]  /Volumes/Alacritty/Alacritty.app
  [unmounted disk image]  /Volumes/BetterTouchTool 5.155/BetterTouchTool.app
  [temp folder]           /private/var/folders/…/Itsycal.app
  [missing]               /Library/…/EdgeUpdater/131.0.2903.69/EdgeUpdater.app
  …

Unregister all 296? [y/N]
```

## No dependencies

It drives the LaunchServices C API — `LSSetDefaultRoleHandlerForContentType`
and friends — through the JavaScript-for-Automation ObjC bridge that ships with
every Mac, and shells out to Apple's own `lsregister` for cleanup.

Everything it calls is part of macOS: `/bin/bash` (works on the stock 3.2),
`osascript`, and base BSD userland. Verified under `env -i` with Homebrew off
`PATH`.

`fzf` is used for the pickers if you have it; otherwise you get a numbered
menu.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/purplecandy/open-with/main/install.sh | bash
```

That downloads the script, checks it is intact, and puts it in `/usr/local/bin`
if you can write there, otherwise `~/.local/bin` (and tells you if that is not
on your `PATH`). Run it again to update. No `sudo` is ever asked for.

To choose the location yourself:

```sh
curl -fsSL https://raw.githubusercontent.com/purplecandy/open-with/main/install.sh \
  | OPEN_WITH_INSTALL_DIR=~/bin bash
```

Prefer to do it by hand? It is a single file, so:

```sh
curl -fsSL -o /usr/local/bin/open-with \
  https://raw.githubusercontent.com/purplecandy/open-with/main/open-with
chmod +x /usr/local/bin/open-with
```

Or just drop the file anywhere on your `PATH`.

Uninstall: `rm "$(command -v open-with)"`. The change log lives at
`~/.local/state/open-with/` if you want that gone too.

## Types

A type can be written however you happen to think of it:

| Form | Example |
|---|---|
| extension | `md`, `.md`, `'*.md'` |
| MIME type | `text/markdown` |
| UTI | `net.daringfireball.markdown` |
| an actual file | `~/notes/todo.md` |

Extensions macOS has no registered type for (`.mdx`, `.astro`, `.envrc`) still
work — they get a dynamic identifier, which is exactly what Finder's
*Get Info → Change All…* does.

Passing a real file uses its extension, and says so before it changes anything:

```
$ open-with ~/notes/report.md -w Zed
Set Zed as the default for:
  md         Markdown Text                TextEdit → Zed

  Note: this applies to every .md file, not just report.md.
  To open one file once, use: open -a Zed report.md
```

## Undo

Changing system defaults is the kind of thing you want to be able to walk back,
so every change is journalled — including the handler each type had *before*.

```
$ open-with history
#    WHEN              APP                  TYPES
1    2026-09-06 18:50  TextEdit             yaml, toml, csv
2    2026-09-06 18:48  Zed                  md, markdown, json

$ open-with undo last
Undo TextEdit from 2026-09-06 18:50:
  public.yaml                          TextEdit → Xcode
  public.toml                          TextEdit → Nova
  public.comma-separated-values-text   TextEdit → Numbers
```

Changes are grouped per invocation, so undo reverts a whole command rather than
one type at a time — and restores each type to its own previous handler, even
when they differed.

`open-with undo` on its own gives you a picker. `open-with undo 2` reverts a
specific entry. The undo is itself journalled, so undoing an undo works as a
redo.

The log is plain TSV at `~/.local/state/open-with/history.tsv` (override with
`$OPEN_WITH_STATE`). Read it with `cut` or `awk` if you like.

**One honest limitation:** macOS can *set* a default handler but has no API to
*remove* one. If a type had no default before you changed it, undo says so and
leaves it alone rather than guessing. `--doctor` sweeps are logged for the audit
trail but are not reversible either — the apps they pointed at no longer exist.

## Options

```
-w, --with APP     application: name, path, or bundle id
-l, --list         show current handlers
-a, --all-apps     list every app, not just capable ones
-d, --doctor       find and remove stale registrations
    --history      list every change this tool has made
    --undo [N]     revert a change
-n, --dry-run      show what would change, change nothing
-y, --yes          skip confirmation
-q, --quiet        only print errors
-h, --help         full help
```

## Caveats

- Finder caches handlers per session. If a change does not appear to take,
  relaunch Finder or log out and back in.
- `.ts` resolves to MPEG-2 Transport Stream, not TypeScript — macOS's opinion,
  not this script's. The picker shows you the resolved type before it commits,
  so you can see it coming.
- Extension→UTI resolution uses `UTTypeCreatePreferredIdentifierForTag`, which
  Apple has deprecated. Its replacement, the `UniformTypeIdentifiers`
  framework, is not importable from JavaScript-for-Automation, so the
  deprecated call is the one that works. Tested on Sequoia (macOS 15).

## License

MIT
