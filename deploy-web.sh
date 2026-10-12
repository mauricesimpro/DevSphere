#!/usr/bin/env bash
#
# deploy-web.sh — build DevSphere for the web and publish it to the
# `gh-pages` branch, which GitHub Pages serves at:
#
#   https://<user>.github.io/<repo>/
#
# No GitHub Actions and no `workflow` token scope required — this pushes a
# built static site straight to the gh-pages branch.
#
# Usage:
#   ./deploy-web.sh              # base href defaults to /DevSphere/
#   ./deploy-web.sh /myrepo/     # override base href to match your repo name

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR"

BASE_HREF="${1:-/DevSphere/}"
REMOTE_URL="$(git remote get-url origin)"

echo "==> Building web (base-href $BASE_HREF)..."
flutter build web --release --base-href "$BASE_HREF"

echo "==> Publishing build/web to gh-pages on $REMOTE_URL"
TMP="$(mktemp -d)"
cp -r build/web/. "$TMP/"
touch "$TMP/.nojekyll"   # stop GitHub Pages from running Jekyll on the output

(
  cd "$TMP"
  git init -q
  git checkout -q -b gh-pages
  git add -A
  git -c user.name="DevSphere Deploy" \
      -c user.email="deploy@devsphere.local" \
      commit -qm "Deploy web build"
  git push -f -q "$REMOTE_URL" gh-pages
)

rm -rf "$TMP"
echo ""
echo "✓ Published. Pages will update shortly at the gh-pages site URL."
