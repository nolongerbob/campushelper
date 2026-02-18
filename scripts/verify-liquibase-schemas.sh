#!/bin/bash
# Проверка идентичности схем БД через Liquibase (ЛР8 п.8)
# Использование: ./scripts/verify-liquibase-schemas.sh

set -e

echo "=========================================="
echo "ЛР8 п.8 — Проверка схем БД через Liquibase"
echo "=========================================="
echo ""

cd "$(dirname "$0")/.."

# Проверка локальной БД (Docker)
echo "=== 1. Проверка локальной БД (Docker) ==="
VOL_NAME=$(docker volume ls --format '{{.Name}}' | grep -E '_db-data|db-data' | head -1)
if [ -n "$VOL_NAME" ]; then
  echo "Volume: $VOL_NAME"
  echo ""
  echo "Применяем миграции Liquibase к локальной БД..."
  docker run --rm --user root \
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
      ./liquibase --driver=org.sqlite.JDBC --url=jdbc:sqlite:/app/campus_helper.db --changeLogFile=/changelog/db.changelog-master.xml status
    " 2>&1 || echo "Liquibase не установлен или БД недоступна"
else
  echo "Volume не найден. Запусти: docker compose up -d"
fi

echo ""
echo "=== 2. Ожидаемый результат Liquibase status ==="
echo "После применения всех миграций должно быть:"
echo "  - 0 changesets pending"
echo "  - или 'All changesets have been executed'"
echo ""

echo "=== 3. Проверка схемы БД ==="
if [ -n "$VOL_NAME" ]; then
  echo "Таблицы в БД:"
  docker compose run --rm db-shell ".tables" 2>/dev/null || echo "Контейнер не запущен"
  echo ""
  echo "Полная схема:"
  docker compose run --rm db-shell ".schema" 2>/dev/null || echo "Контейнер не запущен"
fi

echo ""
echo "=========================================="
echo "Для проверки на Test/Stage/Prod:"
echo "=========================================="
echo ""
echo "На каждом сервере выполни:"
echo "  cd /opt/campus_helper_liquibase"
echo "  liquibase status"
echo ""
echo "Результат должен быть одинаковым на всех серверах:"
echo "  - 0 changesets pending"
echo "  - Все миграции применены (001, 002, 003, 004)"
echo ""
echo "Для сравнения схем через Liquibase diff:"
echo "  liquibase diff --reference-url=jdbc:sqlite:/path/to/test.db"
echo "  (в liquibase.properties указан url к Stage/Prod)"
echo ""
echo "Результат: 'No differences found' или пустой вывод = схемы идентичны."
