#!/usr/bin/env bash
#
# open-with installer
#
#   curl -fsSL https://raw.githubusercontent.com/purplecandy/open-with/main/install.sh | bash
#
# Downloads the open-with script and puts it on your PATH. No sudo, no Homebrew.
#
# Environment overrides:
#   OPEN_WITH_INSTALL_DIR   where to put the binary (default: /usr/local/bin if
#                           writable, otherwise ~/.local/bin)
#   OPEN_WITH_REF           git ref to install (default: main)
#
set -euo pipefail

REPO="purplecandy/open-with"
REF="${OPEN_WITH_REF:-main}"
URL="https://raw.githubusercontent.com/$REPO/$REF/open-with"

if [[ -t 2 && -z "${NO_COLOR:-}" ]]; then
  BOLD=$'\033[1m'; DIM=$'\033[2m'; RED=$'\033[31m'; GREEN=$'\033[32m'
  YELLOW=$'\033[33m'; RESET=$'\033[0m'
else
  BOLD=''; DIM=''; RED=''; GREEN=''; YELLOW=''; RESET=''
fi

die()  { printf '%sinstall:%s %s\n' "$RED" "$RESET" "$*" >&2; exit 1; }
warn() { printf '%s!%s %s\n' "$YELLOW" "$RESET" "$*" >&2; }
info() { printf '%s›%s %s\n' "$DIM" "$RESET" "$*" >&2; }

# ------------------------------------------------------------------ preflight

[[ "$(uname -s)" == "Darwin" ]] || die "open-with only works on macOS (this is $(uname -s))."

if command -v curl >/dev/null 2>&1; then
  fetch() { curl -fsSL "$1" -o "$2"; }
elif command -v wget >/dev/null 2>&1; then
  fetch() { wget -q "$1" -O "$2"; }
else
  die "need curl or wget to download."
fi

# ------------------------------------------------------------ pick a location

pick_install_dir() {
  if [[ -n "${OPEN_WITH_INSTALL_DIR:-}" ]]; then
    printf '%s\n' "$OPEN_WITH_INSTALL_DIR"
    return
  fi
  if [[ -d /usr/local/bin && -w /usr/local/bin ]]; then
    printf '/usr/local/bin\n'
    return
  fi
  printf '%s\n' "$HOME/.local/bin"
}

INSTALL_DIR="$(pick_install_dir)"
INSTALL_DIR="${INSTALL_DIR/#\~/$HOME}"
TARGET="$INSTALL_DIR/open-with"

mkdir -p "$INSTALL_DIR" 2>/dev/null \
  || die "cannot create $INSTALL_DIR. Set OPEN_WITH_INSTALL_DIR to a directory you own."
[[ -w "$INSTALL_DIR" ]] \
  || die "$INSTALL_DIR is not writable. Set OPEN_WITH_INSTALL_DIR to a directory you own."

# ---------------------------------------------------------------- download

TMP="$(mktemp -t open-with.XXXXXX)"
trap 'rm -f "$TMP"' EXIT

info "Downloading open-with ($REF)…"
fetch "$URL" "$TMP" || die "download failed: $URL"

# Sanity: make sure we got the script and not an HTML error page or a truncated file.
head -n 1 "$TMP" | grep -q '^#!/usr/bin/env bash' \
  || die "downloaded file does not look like the open-with script. Refusing to install."
grep -q '^VERSION=' "$TMP" \
  || die "downloaded file is missing its version marker. Refusing to install."
bash -n "$TMP" \
  || die "downloaded script failed a syntax check. Refusing to install."

# ---------------------------------------------------------------- install

PREVIOUS=""
if [[ -x "$TARGET" ]]; then
  PREVIOUS="$("$TARGET" --version 2>/dev/null | awk '{print $2}' || true)"
fi

install -m 755 "$TMP" "$TARGET"
NEW="$("$TARGET" --version 2>/dev/null | awk '{print $2}' || true)"

if [[ -n "$PREVIOUS" && "$PREVIOUS" != "$NEW" ]]; then
  printf '%s✓%s Updated open-with %s → %s at %s\n' "$GREEN" "$RESET" "$PREVIOUS" "$NEW" "$TARGET" >&2
elif [[ -n "$PREVIOUS" ]]; then
  printf '%s✓%s Reinstalled open-with %s at %s\n' "$GREEN" "$RESET" "$NEW" "$TARGET" >&2
else
  printf '%s✓%s Installed open-with %s at %s\n' "$GREEN" "$RESET" "$NEW" "$TARGET" >&2
fi

# ---------------------------------------------------------------- PATH check

case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *)
    warn "$INSTALL_DIR is not on your PATH."
    shell_name="$(basename "${SHELL:-/bin/zsh}")"
    # shellcheck disable=SC2088  # display text, not a path we expand
    case "$shell_name" in
      zsh)  rc="~/.zshrc" ;;
      bash) rc="~/.bash_profile" ;;
      fish) rc="~/.config/fish/config.fish" ;;
      *)    rc="your shell's rc file" ;;
    esac
    if [[ "$shell_name" == "fish" ]]; then
      printf '  Add this to %s:\n\n    fish_add_path %s\n\n' "$rc" "$INSTALL_DIR" >&2
    else
      printf '  Add this to %s:\n\n    export PATH="%s:$PATH"\n\n' "$rc" "$INSTALL_DIR" >&2
    fi
    ;;
esac

printf '\n%sTry:%s  open-with --help\n' "$BOLD" "$RESET" >&2
