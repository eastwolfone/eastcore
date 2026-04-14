#!/bin/bash
# EastCore apply-sql — applies custom SQL patches from custom/sql/
set -e

SQL_DIR=~/eastcore/custom/sql
APPLIED_LOG="$SQL_DIR/.applied"

# Create tracking file if it doesn't exist
touch "$APPLIED_LOG"

echo "=== EastCore SQL Patch Applicator ==="

APPLIED=0

for db_dir in "$SQL_DIR"/*/; do
  [ -d "$db_dir" ] || continue
  db_name="acore_$(basename $db_dir)"

  for sql_file in "$db_dir"*.sql; do
    [ -f "$sql_file" ] || continue

    filename=$(basename "$sql_file")

    # Skip if already applied
    if grep -qF "$filename" "$APPLIED_LOG" 2>/dev/null; then
      continue
    fi

    echo "  Applying [$db_name] $filename..."
    if mysql -u acore -pacore "$db_name" < "$sql_file" 2>/dev/null; then
      echo "$filename" >> "$APPLIED_LOG"
      APPLIED=$((APPLIED + 1))
    else
      echo "  ERROR applying $filename — skipping"
    fi
  done
done

if [ "$APPLIED" -eq 0 ]; then
  echo "No new SQL patches to apply."
else
  echo ""
  echo "Applied $APPLIED patch(es)."
  echo "Tracking file: $APPLIED_LOG"
fi
