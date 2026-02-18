#!/bin/bash
# Применить миграции Liquibase и вывести схему БД через Docker

set -e

echo "=== Пересоздание БД с нуля ==="
sudo docker compose down -v
sudo docker compose up -d --build

echo ""
echo "=== Ожидание запуска контейнера ==="
sleep 5

echo ""
echo "=== Применение миграций (settings, audit_log) через sqlite3 ==="
VOLUME_NAME=$(sudo docker volume ls | grep -E 'documents_db-data|.*_db-data' | head -1 | awk '{print $2}')
if [ -n "$VOLUME_NAME" ]; then
  MIGRATE_SQL=$(mktemp)
  cat << 'SQLEOF' > "$MIGRATE_SQL"
CREATE TABLE IF NOT EXISTS settings ("key" TEXT PRIMARY KEY, value TEXT);
CREATE TABLE IF NOT EXISTS audit_log (id INTEGER PRIMARY KEY AUTOINCREMENT, login TEXT NOT NULL, action TEXT NOT NULL, created_at TEXT DEFAULT (datetime('now')));
SQLEOF
  sudo docker run --rm \
    -v "$VOLUME_NAME:/app" \
    -v "$MIGRATE_SQL:/migrate.sql" \
    --entrypoint "" \
    keinos/sqlite3:latest \
    sqlite3 /app/campus_helper.db ".read /migrate.sql" 2>&1
  rm -f "$MIGRATE_SQL"
  echo "Миграции применены."
else
  echo "Volume не найден, пропускаем миграции."
fi

echo ""
echo "=== Список таблиц ==="
sudo docker compose run --rm db-shell ".tables"

echo ""
echo "=== Полная схема БД ==="
sudo docker compose run --rm db-shell ".schema"

echo ""
echo "=== Схема каждой таблицы ==="
sudo docker compose run --rm db-shell ".schema users" 2>/dev/null || echo "Таблица users не найдена"
sudo docker compose run --rm db-shell ".schema settings" 2>/dev/null || echo "Таблица settings не найдена"
sudo docker compose run --rm db-shell ".schema audit_log" 2>/dev/null || echo "Таблица audit_log не найдена"

echo ""
echo "=== Данные из users ==="
sudo docker compose run --rm db-shell "SELECT * FROM users;" 2>/dev/null || echo "Нет данных"
