#!/bin/bash
# Применить миграции 002 и 003 к БД через sqlite3 (без Liquibase/Java)

set -e

VOLUME_NAME=$(sudo docker volume ls | grep -E 'documents_db-data|.*_db-data' | head -1 | awk '{print $2}')
if [ -z "$VOLUME_NAME" ]; then
  echo "Volume не найден. Запусти: sudo docker compose up -d"
  exit 1
fi

echo "=== Применение миграций через sqlite3 ==="

# Создаём временный SQL-файл без liquibase-комментариев
cat << 'SQL' > /tmp/migrate.sql
CREATE TABLE IF NOT EXISTS settings (
    "key" TEXT PRIMARY KEY,
    value TEXT
);
CREATE TABLE IF NOT EXISTS audit_log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    login TEXT NOT NULL,
    action TEXT NOT NULL,
    created_at TEXT DEFAULT (datetime('now'))
);
SQL

sudo docker run --rm \
  -v "$VOLUME_NAME:/app" \
  -v /tmp/migrate.sql:/migrate.sql \
  keinos/sqlite3:latest \
  sqlite3 /app/campus_helper.db ".read /migrate.sql"

rm -f /tmp/migrate.sql
echo "Миграции применены."
