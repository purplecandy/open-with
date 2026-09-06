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
-q, --quiet        suppress notes and warnings
-h, --help         full help
```

## Caveats

- `--doctor` treats any registered app whose path does not currently exist as
  stale. An app on an external drive that is unplugged right now fits that
  description too. Unregistering it is harmless - macOS re-registers it the
  next time it launches - but you may want to plug the drive in first.
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
