#!/bin/bash
# EastCore database restore — restores databases from a backup timestamp
set -e

BACKUP_DIR=~/eastcore/backups

if [ -z "$1" ]; then
  echo "Usage: restore-db.sh <timestamp>"
  echo ""
  echo "Available backups:"
  ls "$BACKUP_DIR"/*.sql 2>/dev/null | sed 's/.*\//  /' | sed 's/_acore_.*//' | sort -u
  exit 1
fi

TIMESTAMP="$1"

echo "=== EastCore Database Restore ==="
echo "Timestamp: $TIMESTAMP"
echo "WARNING: This will overwrite current databases!"
read -p "Continue? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi

for DB in acore_auth acore_characters acore_world; do
  FILE="$BACKUP_DIR/${TIMESTAMP}_${DB}.sql"
  if [ -f "$FILE" ]; then
    echo "Restoring $DB..."
    mysql -u acore -pacore "$DB" < "$FILE"
    echo "  -> done"
  else
    echo "  Skipping $DB (file not found: $FILE)"
  fi
done

echo ""
echo "Restore complete."
