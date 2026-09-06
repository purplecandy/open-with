# open-with

Choose which app opens a kind of file on your Mac. One line in the Terminal.

![open-with demo](demo.gif)

## Install

Paste this into Terminal and press Enter:

```sh
curl -fsSL https://raw.githubusercontent.com/purplecandy/open-with/main/install.sh | bash
```

That is all. It needs macOS 12 or newer and nothing else. Run the same line
again to update.

## Use it

Open all Markdown and JSON files in Zed:

```sh
open-with md json -w Zed
```

Open every kind of image in Preview:

```sh
open-with @images -w Preview
```

Not sure what to type? Run it with nothing. It will ask you:

```sh
open-with
```

See what opens what right now:

```sh
open-with -l
```

Changed your mind? Put it back:

```sh
open-with undo last
```

## Groups

Put `@` in front of a word to mean a whole set of file types.

| Group | What it covers |
|---|---|
| `@text` | txt, md, log, ... |
| `@docs` | pdf, doc, docx, xls, ppt, ... |
| `@data` | json, yaml, xml, csv, ... |
| `@code` | py, go, rs, java, sh, ... |
| `@web` | html, css, js, ts, ... |
| `@images` | png, jpg, gif, heic, ... |
| `@audio` | mp3, wav, flac, ... |
| `@video` | mp4, mov, mkv, ... |
| `@archives` | zip, tar, gz, dmg, ... |
| `@media` | images, audio and video together |

`open-with --groups` shows the full list.

## When an app "cannot be opened"

Sometimes macOS says an app was moved to the Trash when it is right there in
your Applications folder. Old, broken records cause this. This cleans them up:

```sh
open-with --doctor
```

## Options

```
-w, --with APP     the app to use
-l, --list         show what opens what
    --groups       show the @groups
-d, --doctor       clean up broken app records
    --history      show every change made by this tool
    --undo [N]     take a change back
-n, --dry-run      show what would change, but change nothing
-y, --yes          do not ask before changing
-h, --help         full help
```

## More

How it works, all the ways to name a type, and known quirks:
[DETAILS.md](DETAILS.md)

## License

MIT
