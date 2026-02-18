#!/bin/bash
# Продублировать новую схему БД на Test (ЛР8)
# Применяет все миграции через Liquibase и показывает схему

set -e

echo "=========================================="
echo "Продублирование новой схемы БД на Test"
echo "=========================================="
echo ""

cd "$(dirname "$0")/.."

# Останавливаем сервер если запущен
echo "=== Остановка сервера (разблокировка БД) ==="
sudo docker compose stop server 2>/dev/null || true

# Применяем миграции через Liquibase
echo ""
echo "=== Применение миграций через Liquibase ==="
VOL_NAME=$(sudo docker volume ls --format '{{.Name}}' | grep -E '_db-data|db-data' | head -1)
if [ -z "$VOL_NAME" ]; then
  echo "Volume не найден. Запусти: docker compose up -d"
  exit 1
fi

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
    echo 'Применение миграций...'
    ./liquibase --driver=org.sqlite.JDBC --url=jdbc:sqlite:/app/campus_helper.db --changeLogFile=/changelog/db.changelog-master.xml update
    echo ''
    echo 'Статус миграций:'
    ./liquibase --driver=org.sqlite.JDBC --url=jdbc:sqlite:/app/campus_helper.db --changeLogFile=/changelog/db.changelog-master.xml status
  " 2>&1

# Запускаем сервер
echo ""
echo "=== Запуск сервера ==="
sudo docker compose start server 2>&1
sleep 2

# Показываем схему БД
echo ""
echo "=========================================="
echo "Схема базы данных на Test:"
echo "=========================================="
echo ""

echo "=== Список таблиц ==="
sudo docker compose run --rm db-shell ".tables" 2>&1

echo ""
echo "=== Полная схема БД ==="
sudo docker compose run --rm db-shell ".schema" 2>&1

echo ""
echo "=== Схема каждой таблицы ==="
sudo docker compose run --rm db-shell ".schema users" 2>/dev/null
sudo docker compose run --rm db-shell ".schema settings" 2>/dev/null
sudo docker compose run --rm db-shell ".schema audit_log" 2>/dev/null
sudo docker compose run --rm db-shell ".schema medicine_new" 2>/dev/null

echo ""
echo "=========================================="
echo "Схема БД на Test продублирована."
echo "Все миграции применены через Liquibase."
echo "=========================================="
