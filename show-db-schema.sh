#!/bin/bash
# Применить миграции Liquibase и вывести схему БД через Docker

set -e

echo "=== Пересоздание БД с нуля ==="
sudo docker compose down -v
sudo docker compose up -d --build

echo ""
echo "=== Ожидание запуска контейнера (сервер создаёт БД) ==="
sleep 5

echo ""
echo "=== Останавливаем сервер, чтобы разблокировать БД для миграций ==="
sudo docker compose stop server 2>/dev/null || true

echo "=== Применение миграций через Liquibase ==="
VOL_NAME=$(sudo docker volume ls --format '{{.Name}}' | grep -E '_db-data|db-data' | head -1)
if [ -n "$VOL_NAME" ]; then
  sudo docker run --rm --user root \
    -v "$VOL_NAME:/app" \
    -v "$(pwd)/database/changelog:/changelog" \
    -w /app \
    ubuntu:22.04 \
    bash -c "
      export DEBIAN_FRONTEND=noninteractive
      apt-get update -qq >/dev/null 2>&1
      apt-get install -y -qq openjdk-17-jre-headless wget >/dev/null 2>&1
      wget -q https://github.com/liquibase/liquibase/releases/download/v4.24.0/liquibase-4.24.0.tar.gz -O /tmp/lb.tar.gz
      tar -xzf /tmp/lb.tar.gz -C /tmp
      cd /tmp
      chmod +x liquibase
      echo '=== Liquibase update (применение миграций) ==='
      ./liquibase --driver=org.sqlite.JDBC --url=jdbc:sqlite:/app/campus_helper.db --changeLogFile=/changelog/db.changelog-master.xml update
      echo ''
      echo '=== Liquibase status (проверка применённых миграций) ==='
      ./liquibase --driver=org.sqlite.JDBC --url=jdbc:sqlite:/app/campus_helper.db --changeLogFile=/changelog/db.changelog-master.xml status
    " 2>&1
  echo ""
  echo "Миграции применены через Liquibase."
else
  echo "Volume не найден, применяем через sqlite3..."
  sudo docker compose run --rm --user root --entrypoint "" db-shell sqlite3 /app/campus_helper.db "CREATE TABLE IF NOT EXISTS settings (\"key\" TEXT PRIMARY KEY, value TEXT); CREATE TABLE IF NOT EXISTS audit_log (id INTEGER PRIMARY KEY AUTOINCREMENT, login TEXT NOT NULL, action TEXT NOT NULL, created_at TEXT DEFAULT (datetime('now'))); CREATE TABLE IF NOT EXISTS medicine_new (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, quantity INTEGER NOT NULL DEFAULT 0);" 2>&1
fi

echo "=== Запускаем сервер снова ==="
sudo docker compose start server 2>&1
sleep 2

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
sudo docker compose run --rm db-shell ".schema medicine_new" 2>/dev/null || echo "Таблица medicine_new не найдена"

echo ""
echo "=== Данные из users ==="
sudo docker compose run --rm db-shell "SELECT * FROM users;" 2>/dev/null || echo "Нет данных"
