#!/usr/bin/env sh
# Simple Postgres backup via pg_dump.
# Usage: DB_HOST=localhost DB_DATABASE=zaban ./scripts/backup-db.sh

set -eu

DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USERNAME="${DB_USERNAME:-postgres}"
DB_DATABASE="${DB_DATABASE:-zaban}"
OUT_DIR="${OUT_DIR:-./backups}"
STAMP="$(date +%Y%m%d_%H%M%S)"
FILE="${OUT_DIR}/zaban_${STAMP}.sql"

mkdir -p "$OUT_DIR"
PGPASSWORD="${DB_PASSWORD:-postgres}" pg_dump \
  -h "$DB_HOST" \
  -p "$DB_PORT" \
  -U "$DB_USERNAME" \
  -d "$DB_DATABASE" \
  -F p \
  -f "$FILE"

echo "Backup written to $FILE"
