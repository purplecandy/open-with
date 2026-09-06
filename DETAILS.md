# Details

The finer points. Nothing here is needed to use `open-with`.

## Install options

The installer puts the script in `/usr/local/bin` if you can write there,
otherwise in `~/.local/bin`, and tells you if that folder is not on your `PATH`.
It never asks for `sudo`.

Pick the folder yourself:

```sh
curl -fsSL https://raw.githubusercontent.com/purplecandy/open-with/main/install.sh \
  | OPEN_WITH_INSTALL_DIR=~/bin bash
```

Or skip the installer. It is one file:

```sh
curl -fsSL -o /usr/local/bin/open-with \
  https://raw.githubusercontent.com/purplecandy/open-with/main/open-with
chmod +x /usr/local/bin/open-with
```

Uninstall with `rm "$(command -v open-with)"`. The change log lives in
`~/.local/state/open-with/` if you want that gone too.

## Ways to name a type

| Form | Example |
|---|---|
| extension | `md`, `.md`, `'*.md'` |
| MIME type | `text/markdown` |
| UTI | `net.daringfireball.markdown` |
| a real file | `~/notes/todo.md` |
| a group | `@images`, `@code`, `@media` |

Mix them freely. Extensions macOS has no registered type for (`.mdx`, `.astro`,
`.envrc`) still work. They get a dynamic identifier, which is exactly what
Finder's *Get Info → Change All…* does.

The interactive picker lists about 130 common types. Anything not in that list
can be typed into the picker, or passed on the command line.

The `@` on a group is what keeps `open-with zip` (the `.zip` extension) apart
from `open-with @zip` (every archive type). Aliases: `@txt` for `@text`,
`@img` for `@images`, `@zip` for `@archives`.

Passing a real file uses its extension, and says so before changing anything:

```
$ open-with ~/notes/report.md -w Zed
Set Zed as the default for:
  md         Markdown Text                TextEdit → Zed

  Note: this applies to every .md file, not just report.md.
  To open one file once, use: open -a Zed report.md
```

## Undo

Every change is written to `~/.local/state/open-with/history.tsv` along with
the app each type had before. `open-with history` lists them, grouped by
command. `open-with undo last` reverts the most recent one, `open-with undo 3`
a specific one, and `open-with undo` on its own gives you a picker. Undo is
itself logged, so undoing an undo is a redo.

macOS can set a default app but has no way to remove one. If a type had no
default before you changed it, undo says so and leaves it alone.

Set `OPEN_WITH_STATE` to keep the log somewhere else.

## How it works

Everything it calls ships with macOS: `/bin/bash` (the stock 3.2 is fine),
`osascript`, and the usual BSD tools. No Homebrew, no compiler. If `fzf` is
installed the pickers use it; otherwise you get a numbered menu.

It talks to LaunchServices through Apple's current APIs, `NSWorkspace` and
`UTType`, using the JavaScript-for-Automation bridge. Cleanup of broken records
shells out to Apple's own `lsregister`.

Two quirks of doing this from JavaScript-for-Automation:

- The `UniformTypeIdentifiers` framework has no bridge metadata, so it cannot
  be imported directly. The script asks the ObjC runtime for the `UTType` class
  instead, which works because AppKit has already loaded the framework.
- Setting a default goes through an asynchronous NSWorkspace call whose
  completion callback the bridge cannot receive. The script pumps the run loop
  and waits up to three seconds for the change to show up, then reports success
  or failure from what it reads back.

Tested on Sequoia (macOS 15). Needs macOS 12 or later.

## Known quirks

- `--doctor` treats any registered app whose path does not exist right now as
  broken. An app on an unplugged external drive fits that description too.
  Removing its record is harmless, since macOS re-registers it on next launch,
  but you may want to plug the drive in first.
- Setting a default scans the LaunchServices database first, which takes a few
  seconds on a machine with many apps.
- Finder caches defaults per session. If a change does not seem to take,
  relaunch Finder or log out and back in.
- `.ts` means MPEG-2 Transport Stream to macOS, not TypeScript. The
  confirmation step shows the resolved type before anything changes.
