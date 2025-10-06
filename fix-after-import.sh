#!/bin/bash
#
# This script performs two tasks:
#
# 1. It fixes trailing newline issues: for every file modified relative to HEAD,
#    if the file does not end in a newline, one is appended.
#
# 2. It fixes file permission (mode) changes:
#    By default, it only adjusts files where the content is identical to HEAD (mode-only change).
#    If you pass --force-permissions, it will force the permission fix even when content has changed.
#
# Usage:
#   ./fix_newlines_and_permissions.sh [--force-permissions]
#

usage() {
  echo "Usage: $0 [--force-permissions, --no-newline]"
  exit 1
}

# Default: only fix mode if content is identical.
FORCE_PERMS=0
NEWLINE=1
while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --force-permissions) FORCE_PERMS=1 ;;
    --no-newline) NEWLINE=0 ;;
    --help) usage ;;
    *) echo "Unknown parameter: $1" && usage ;;
  esac
  shift
done

# ----------------------------------------------------------------------------
# Function: fix_trailing_newline
# Adds a trailing newline to a file if it does not already end with one.
# ----------------------------------------------------------------------------
fix_trailing_newline() {
  local file="$1"
  # Skip empty files.
  if [ ! -s "$file" ]; then
    return
  fi
  local last_char
  last_char=$(tail -c 1 "$file")
  if [ "$last_char" != $'\n' ]; then
    echo >> "$file"
    echo "Added trailing newline to: '$file'"
  fi
}

# ----------------------------------------------------------------------------
# Function: reset_permissions
# Resets a file's permissions to what is stored in HEAD.
# ----------------------------------------------------------------------------
reset_permissions() {
  local file="$1"
  local mode_line mode perm
  mode_line=$(git ls-tree HEAD "$file")
  if [ -z "$mode_line" ]; then
    echo "Warning: Could not retrieve mode for '$file' from HEAD. Skipping."
    return
  fi
  mode=$(echo "$mode_line" | awk '{print $1}')
  # Assuming mode is in the form 100644, extract the last three digits.
  perm=${mode:3}
  chmod "$perm" "$file"
  echo "Fixed permissions for: '$file' to $perm"
}

echo "Step 1: Fixing trailing newlines in modified files..."
if [ "$NEWLINE" -eq 1 ]; then
  # Process modified files as reported by git diff.
  git diff --name-only -z HEAD | while IFS= read -r -d '' file; do
    if [ -f "$file" ]; then
      fix_trailing_newline "$file"
    fi
  done
fi

echo "Step 2: Fixing file permissions (mode changes)..."
# Process raw diff output with improved parsing.
# Each line of git diff --raw -z HEAD is of the format:
#   :<old_mode> <new_mode> <old_blob> <new_blob> <status>\t<file_path>
git diff --raw -z HEAD | while IFS= read -r -d '' line; do
  # Split the line into a header (before the tab) and the file path (after the tab)
  header="${line%%$'\t'*}"
  file_path="${line#*$'\t'}"
  
  # Split header into its fields using shell 'read' (where fields are separated by spaces)
  read -r old_mode new_mode old_blob new_blob status <<< "$header"
  # Remove the leading colon from old_mode.
  old_mode_clean="${old_mode#:}"
  
  # If new_blob consists only of zeros, treat it as a mode-only change
  if [[ "$new_blob" =~ ^0+$ ]]; then
    new_blob="$old_blob"
  fi
  
  # Process file if the mode has changed.
  if [ "$old_mode_clean" != "$new_mode" ]; then
    if [ "$FORCE_PERMS" -eq 0 ]; then
      # Only fix permissions if content remains unchanged.
      if [ "$old_blob" = "$new_blob" ]; then
        if [ -f "$file_path" ]; then
          reset_permissions "$file_path"
        fi
      fi
    else
      # Force permission fix regardless of content changes.
      if [ -f "$file_path" ]; then
        reset_permissions "$file_path"
      fi
    fi
  fi
done

echo "All fixes complete."