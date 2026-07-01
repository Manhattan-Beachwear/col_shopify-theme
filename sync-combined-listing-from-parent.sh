#!/bin/bash
# sync-combined-listing-from-parent.sh
# Pull the Combined Listing Variant Picker file bundle from parent (upstream).
#
# Usage:
#   ./sync-combined-listing-from-parent.sh           # fetch + checkout files
#   ./sync-combined-listing-from-parent.sh --dry-run # show what would change
#   ./sync-combined-listing-from-parent.sh --diff    # diff each file vs upstream
#
# Prerequisites:
#   git remote add upstream https://github.com/Manhattan-Beachwear/tlc_shopify_theme.git
#
# After running:
#   git status
#   git diff   # review before commit
#
# WARNING: Parent may contain known bugs (e.g. corrupted <variant-picker-cl-dual>
# opening tag). Do not commit blindly — compare against your local fixes first.

set -euo pipefail

REMOTE="${PARENT_REMOTE:-upstream}"
BRANCH="${PARENT_BRANCH:-main}"
MANIFEST="$(dirname "$0")/COMBINED_LISTING_FILES.txt"
DRY_RUN=false
DIFF_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=true; shift ;;
    --diff)    DIFF_ONLY=true; shift ;;
    --help)
      echo "Usage: $0 [--dry-run | --diff]"
      echo "  --dry-run  List files that would be checked out from $REMOTE/$BRANCH"
      echo "  --diff     Show diff for each manifest file vs $REMOTE/$BRANCH"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if ! git remote get-url "$REMOTE" &>/dev/null; then
  echo "❌ Remote '$REMOTE' not found."
  echo "   Run: git remote add upstream https://github.com/Manhattan-Beachwear/tlc_shopify_theme.git"
  exit 1
fi

if [[ ! -f "$MANIFEST" ]]; then
  echo "❌ Manifest not found: $MANIFEST"
  exit 1
fi

FILES=()
while IFS= read -r line || [[ -n "$line" ]]; do
  FILES+=("$line")
done < <(grep -v '^#' "$MANIFEST" | grep -v '^[[:space:]]*$' || true)

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "❌ No files listed in $MANIFEST"
  exit 1
fi

echo "📡 Fetching $REMOTE/$BRANCH..."
if [[ "$DRY_RUN" == "false" && "$DIFF_ONLY" == "false" ]]; then
  git fetch "$REMOTE" "$BRANCH"
fi

if [[ "$DIFF_ONLY" == "true" ]]; then
  echo ""
  echo "Diff vs $REMOTE/$BRANCH:"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  changed=0
  for f in "${FILES[@]}"; do
    if git cat-file -e "$REMOTE/$BRANCH:$f" 2>/dev/null; then
      if git diff --quiet HEAD "$REMOTE/$BRANCH" -- "$f" 2>/dev/null; then
        echo "  ✓ same  $f"
      else
        echo "  ≠ diff  $f"
        changed=$((changed + 1))
      fi
    else
      echo "  ⚠ missing in parent  $f"
    fi
  done
  echo ""
  echo "$changed file(s) differ from $REMOTE/$BRANCH (committed HEAD)."
  exit 0
fi

if [[ "$DRY_RUN" == "true" ]]; then
  echo ""
  echo "[DRY RUN] Would checkout from $REMOTE/$BRANCH:"
  for f in "${FILES[@]}"; do
    if git cat-file -e "$REMOTE/$BRANCH:$f" 2>/dev/null; then
      echo "  ✓ $f"
    else
      echo "  ⚠ not in parent: $f"
    fi
  done
  echo ""
  echo "No changes made."
  exit 0
fi

echo ""
echo "📥 Checking out ${#FILES[@]} files from $REMOTE/$BRANCH..."
missing=()
for f in "${FILES[@]}"; do
  if git cat-file -e "$REMOTE/$BRANCH:$f" 2>/dev/null; then
    git checkout "$REMOTE/$BRANCH" -- "$f"
    echo "  ✓ $f"
  else
    missing+=("$f")
    echo "  ⚠ skipped (not in parent): $f"
  fi
done

echo ""
if [[ ${#missing[@]} -gt 0 ]]; then
  echo "⚠ ${#missing[@]} file(s) not found in parent."
fi

echo "✅ Done. Review with: git status && git diff"
echo ""
echo "⚠ Parent may still have CL bugs (corrupted opening tag, combined-color matching)."
echo "  Compare snippets/variant-combined-listing-picker.liquid line ~1317 before committing."
