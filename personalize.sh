#!/usr/bin/env bash
set -euo pipefail

# personalize.sh
# Interactively (or via flags/env) replace placeholder tokens with real user identity.
# Placeholders:
#   YOUR_GITHUB_USERNAME
#   YOUR_NAME
#   YOUR_EMAIL@example.com

usage() {
  cat <<EOF
Usage: ./personalize.sh [options]
Options:
  --github <username>   GitHub username (or set GITHUB_USERNAME)
  --name <full name>    Full name (or set REAL_NAME)
  --email <email>       Email (or set REAL_EMAIL)
  --dry-run             Show planned changes only
  --no-backup           Do not create .bak files
  --force               Proceed even if some placeholders missing
  -h, --help            Show this help

Environment variables alternative:
  GITHUB_USERNAME, REAL_NAME, REAL_EMAIL

Replaces placeholders in: README.md, bootstrap.sh, .gitconfig (if placeholder present), plus any other text files containing them.
EOF
}

DRY_RUN=false
BACKUP=true
FORCE=false
GITHUB_USERNAME="${GITHUB_USERNAME:-}"
REAL_NAME="${REAL_NAME:-}"
REAL_EMAIL="${REAL_EMAIL:-}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --github) GITHUB_USERNAME="$2"; shift 2;;
    --name) REAL_NAME="$2"; shift 2;;
    --email) REAL_EMAIL="$2"; shift 2;;
    --dry-run) DRY_RUN=true; shift;;
    --no-backup) BACKUP=false; shift;;
    --force) FORCE=true; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown option: $1" >&2; usage; exit 1;;
  esac
done

require() {
  local var_name="$1"; local value="$2"; local desc="$3"
  if [[ -z "$value" ]]; then
    read -rp "$desc: " value
    printf -v "$var_name" '%s' "$value"
  fi
}

require GITHUB_USERNAME "$GITHUB_USERNAME" "GitHub username"
require REAL_NAME "$REAL_NAME" "Full name"
require REAL_EMAIL "$REAL_EMAIL" "Email"

echo "Using:"
echo "  GitHub: $GITHUB_USERNAME"
echo "  Name:   $REAL_NAME"
echo "  Email:  $REAL_EMAIL"

PLACEHOLDERS=("YOUR_GITHUB_USERNAME" "YOUR_NAME" "YOUR_EMAIL@example.com")
REPLACEMENTS=("$GITHUB_USERNAME" "$REAL_NAME" "$REAL_EMAIL")

# Collect candidate files (only text files in repo root depth 2) containing placeholders
mapfile -t CANDIDATES < <(grep -RIl --exclude-dir .git -e 'YOUR_GITHUB_USERNAME' -e 'YOUR_NAME' -e 'YOUR_EMAIL@example.com' . || true)

if [[ ${#CANDIDATES[@]} -eq 0 ]]; then
  echo "No files with placeholders found.";
  exit 0
fi

echo "Files to process:";
printf '  %s\n' "${CANDIDATES[@]}"

do_replace() {
  local file="$1"
  $BACKUP && cp "$file" "$file.bak" || true
  # macOS sed -i requires an arg ('' for none)
  for i in "${!PLACEHOLDERS[@]}"; do
    local ph="${PLACEHOLDERS[$i]}"; local rep="${REPLACEMENTS[$i]}"
    [[ -z "$rep" ]] && continue
    if grep -q "$ph" "$file"; then
      sed -i '' "s|$ph|$rep|g" "$file"
    fi
  done
}

if $DRY_RUN; then
  echo "Dry run complete (no changes made)."
  exit 0
fi

for f in "${CANDIDATES[@]}"; do
  do_replace "$f"
done

echo "Replacement complete. Review git diff and remove any *.bak files when satisfied."
echo "Suggested next step: git add -p && git commit -m 'Personalize placeholders'"