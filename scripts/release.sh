#!/usr/bin/env bash
# Usage: release.sh <major|minor|patch>
# Computes the next semantic version from git tags, updates CHANGELOG.md, tags the commit.
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
BUMP="${1:?major|minor|patch}"

cd "$ROOT_DIR"
last="$(git tag --list 'v*' --sort=-v:refname | head -n1 || true)"
last="${last:-v0.0.0}"
IFS=. read -r MA MI PA <<<"${last#v}"
case "$BUMP" in
  major) MA=$((MA+1)); MI=0; PA=0 ;;
  minor) MI=$((MI+1)); PA=0 ;;
  patch) PA=$((PA+1)) ;;
  *) die "bump must be major, minor or patch" ;;
esac
next="v$MA.$MI.$PA"

range="${last}..HEAD"; [ "$last" = "v0.0.0" ] && range="HEAD"
{
  echo "## $next - $(date -u +%F)"
  git log "$range" --pretty='- %s (%h)'
  echo
  [ -f CHANGELOG.md ] && cat CHANGELOG.md
  true
} >CHANGELOG.md.new && mv CHANGELOG.md.new CHANGELOG.md

git add CHANGELOG.md && git commit -qm "chore(release): $next" || true
git tag -a "$next" -m "Release $next"
log "tagged $next (push with: git push origin main --follow-tags)"
