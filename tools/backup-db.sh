#!/bin/bash
# EastCore database backup — dumps all 3 databases to timestamped files
set -e

BACKUP_DIR=~/eastcore/backups
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

echo "=== EastCore Database Backup ==="
echo "Timestamp: $TIMESTAMP"

echo "Backing up acore_auth..."
mysqldump -u acore -pacore acore_auth > "$BACKUP_DIR/${TIMESTAMP}_acore_auth.sql" 2>/dev/null
echo "  -> ${TIMESTAMP}_acore_auth.sql"

echo "Backing up acore_characters..."
mysqldump -u acore -pacore acore_characters > "$BACKUP_DIR/${TIMESTAMP}_acore_characters.sql" 2>/dev/null
echo "  -> ${TIMESTAMP}_acore_characters.sql"

echo "Backing up acore_world..."
mysqldump -u acore -pacore acore_world > "$BACKUP_DIR/${TIMESTAMP}_acore_world.sql" 2>/dev/null
echo "  -> ${TIMESTAMP}_acore_world.sql"

echo ""
echo "Backup complete. Files in $BACKUP_DIR/"
du -sh "$BACKUP_DIR/${TIMESTAMP}"_*.sql
