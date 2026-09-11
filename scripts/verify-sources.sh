#!/usr/bin/env bash
# Verify the provenance of the binaries this project asks you to install.
#
# Usage:
#   scripts/verify-sources.sh                 run cask + app checks
#   scripts/verify-sources.sh cask            check the Sikarugir Homebrew cask
#   scripts/verify-sources.sh app             check the installed Creator app
#   scripts/verify-sources.sh engine <name>   check one Wine engine tarball
#   scripts/verify-sources.sh all             all of the above, default engine
#
# See docs/sikarugir.md for what each check proves and what it does not.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KNOWN_GOOD="$REPO_ROOT/checksums/known-good.txt"

TAP="sikarugir-app/sikarugir"
CASK="$TAP/sikarugir"
APP="/Applications/Sikarugir Creator.app"
ENGINE_BASE="https://github.com/Sikarugir-App/Engines/releases/download/v1.0"
DEFAULT_ENGINE="WS12WineSikarugir10.0_6"

pass() { printf '  \033[32mPASS\033[0m  %s\n' "$1"; }
fail() { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; FAILURES=$((FAILURES + 1)); }
warn() { printf '  \033[33mWARN\033[0m  %s\n' "$1"; }
info() { printf '        %s\n' "$1"; }
head1() { printf '\n\033[1m%s\033[0m\n' "$1"; }

FAILURES=0
TMPFILES=()
cleanup() { [[ ${#TMPFILES[@]} -gt 0 ]] && rm -f "${TMPFILES[@]}"; return 0; }
trap cleanup EXIT

expected_sha() {
  # $1 = artifact filename as recorded in checksums/known-good.txt
  awk -v f="$1" '$2 == f { print $1 }' "$KNOWN_GOOD"
}

check_cask() {
  head1 "Homebrew cask: $CASK"

  local tap_dir cask_file pinned live cached url
  tap_dir="$(brew --repo "$TAP" 2>/dev/null || true)"
  if [[ -z "$tap_dir" || ! -d "$tap_dir" ]]; then
    fail "tap not installed; run: brew tap $TAP"
    return
  fi

  cask_file="$(find "$tap_dir" -name 'sikarugir.rb' -print -quit)"
  pinned="$(awk -F'"' '/^[[:space:]]*sha256/ { print $2 }' "$cask_file")"
  url="$(awk -F'"' '/^[[:space:]]*url/ { print $2 }' "$cask_file" | sed "s/#{version}/$(awk -F'"' '/^[[:space:]]*version/ { print $2 }' "$cask_file")/g")"
  info "url: $url"

  # 1. The cask pin must match what we recorded as known-good.
  local recorded
  recorded="$(expected_sha "Creator-v1.0.1.tar.xz")"
  if [[ -n "$recorded" && "$pinned" == "$recorded" ]]; then
    pass "cask sha256 matches checksums/known-good.txt"
  else
    fail "cask sha256 ($pinned) does not match known-good ($recorded)"
    info "the cask was updated; review the diff before trusting the new pin"
  fi

  # 2. The live asset must still hash to the pin. Catches an asset replaced
  #    in place under an unchanged tag.
  live="$(curl -fsSL --max-time 180 "$url" | shasum -a 256 | cut -d' ' -f1)"
  if [[ "$live" == "$pinned" ]]; then
    pass "live download matches the cask pin"
  else
    fail "live download ($live) does not match the cask pin ($pinned)"
  fi

  # 3. What actually landed on this machine.
  cached="$(find "$(brew --cache)/downloads" -name '*Creator*' -print 2>/dev/null | head -1)"
  if [[ -n "$cached" ]]; then
    local local_sha
    local_sha="$(shasum -a 256 "$cached" | cut -d' ' -f1)"
    if [[ "$local_sha" == "$pinned" ]]; then
      pass "local Homebrew cache matches the cask pin"
    else
      fail "local cache ($local_sha) does not match the cask pin"
    fi
  else
    info "no cached download found (cache may have been cleaned)"
  fi

  # 4. Who publishes it.
  if command -v gh >/dev/null 2>&1; then
    local publisher
    publisher="$(gh api repos/Sikarugir-App/Creator/releases/tags/v1.0.1 --jq '.author.login' 2>/dev/null || echo "")"
    if [[ "$publisher" == "Gcenx" ]]; then
      pass "release published by Gcenx"
    elif [[ -n "$publisher" ]]; then
      fail "release published by '$publisher', expected Gcenx"
    else
      info "could not read publisher (gh not authenticated?)"
    fi
  fi

  # 5. Tap commit authors. A new name here is not proof of anything, but it is
  #    the thing to look at before pulling an update.
  info "tap commit authors:"
  git -C "$tap_dir" log --format='%an' | sort | uniq -c | sort -rn | sed 's/^/          /'
}

check_app() {
  head1 "Installed app: $APP"

  if [[ ! -d "$APP" ]]; then
    fail "not installed"
    return
  fi

  # The cask ad-hoc re-signs the bundle on purpose, so an ad-hoc signature is
  # expected here. A Developer ID signature would be a surprise, not a problem.
  local sig
  sig="$(codesign -dvvv "$APP" 2>&1 | awk -F= '/^Signature=/ { print $2 }')"
  info "signature: ${sig:-none}"
  if [[ "$sig" == "adhoc" ]]; then
    pass "ad-hoc signature, as the cask's postflight produces"
  else
    warn "unexpected signature state; see docs/sikarugir.md"
  fi

  # The point of this check: the app must only reach Sikarugir-App on GitHub.
  head1 "Network endpoints embedded in the app"
  local urls
  urls="$(find "$APP" -type f \( -perm -u+x -o -name '*.dylib' \) -exec strings -a {} \; 2>/dev/null \
    | grep -Eio 'https?://[a-z0-9._~:/?#@!$&()*+,;=%-]+' | sort -u || true)"
  if [[ -z "$urls" ]]; then
    warn "no URLs found; the bundle layout may have changed"
    return
  fi
  local unexpected=0
  while IFS= read -r u; do
    if [[ "$u" =~ ^https://(github\.com|raw\.githubusercontent\.com)/Sikarugir-App/ ]]; then
      info "ok        $u"
    else
      fail "unexpected endpoint: $u"
      unexpected=1
    fi
  done <<< "$urls"
  if [[ $unexpected -eq 0 ]]; then
    pass "all endpoints are Sikarugir-App on GitHub"
  fi
}

check_engine() {
  local engine="${1:-$DEFAULT_ENGINE}"
  head1 "Wine engine: $engine"

  if [[ "$engine" == *32Bit* ]]; then
    warn "32-bit engine; CARLA ships 64-bit binaries only"
  fi

  local tmp recorded actual
  tmp="$(mktemp -t engine)"
  TMPFILES+=("$tmp")

  info "downloading (~160 MB)..."
  curl -fsSL --max-time 600 -o "$tmp" "$ENGINE_BASE/$engine.tar.xz"
  actual="$(shasum -a 256 "$tmp" | cut -d' ' -f1)"
  recorded="$(expected_sha "$engine.tar.xz")"

  if [[ -z "$recorded" ]]; then
    warn "no recorded checksum for this engine"
    info "if you trust this download, add it to checksums/known-good.txt:"
    info "$actual  $engine.tar.xz"
  elif [[ "$actual" == "$recorded" ]]; then
    pass "matches checksums/known-good.txt"
  else
    fail "sha256 changed"
    info "recorded: $recorded"
    info "actual:   $actual"
  fi

  # D3DMetal needs a Metal-capable Wine build. Every engine checked so far
  # carries winemetal; an engine without it cannot drive CARLA.
  if tar -tJf "$tmp" 2>/dev/null | grep -q winemetal; then
    pass "carries winemetal (D3DMetal capable)"
  else
    fail "no winemetal; this engine cannot run CARLA with D3DMetal"
  fi

  local version
  version="$(tar -xJOf "$tmp" wswine.bundle/version 2>/dev/null | tr -d '\n' || true)"
  if [[ -n "$version" ]]; then
    info "wine version: $version"
  fi
}

main() {
  case "${1:-default}" in
    cask)   check_cask ;;
    app)    check_app ;;
    engine) check_engine "${2:-}" ;;
    all)    check_cask; check_app; check_engine "${2:-}" ;;
    default) check_cask; check_app ;;
    *) echo "unknown check: $1" >&2; exit 2 ;;
  esac

  head1 "Result"
  if [[ $FAILURES -eq 0 ]]; then
    printf '  \033[32mno failures\033[0m\n\n'
  else
    printf '  \033[31m%d check(s) failed\033[0m — see docs/sikarugir.md\n\n' "$FAILURES"
    exit 1
  fi
}

main "$@"
