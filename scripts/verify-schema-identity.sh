#!/bin/bash
# Проверка идентичности схем БД на Test/Stage/Prod (ЛР8 п.8)
# Использование: ./scripts/verify-schema-identity.sh

set -e

echo "=========================================="
echo "ЛР8 п.8 — Проверка идентичности схем БД"
echo "=========================================="
echo ""

# Для локальной проверки (Docker) — схема из текущей БД
echo "=== Схема БД (локально через Docker) ==="
if docker compose ps server 2>/dev/null | grep -q "Up"; then
  echo "Список таблиц:"
  docker compose run --rm db-shell ".tables" 2>/dev/null || echo "Контейнер не запущен"
  echo ""
  echo "Полная схема:"
  docker compose run --rm db-shell ".schema" 2>/dev/null || echo "Контейнер не запущен"
else
  echo "Запусти: docker compose up -d"
fi

echo ""
echo "=========================================="
echo "Для проверки на Test/Stage/Prod:"
echo "=========================================="
echo ""
echo "1. На Test-сервере выполни:"
echo "   cd /opt/campus_helper_liquibase"
echo "   liquibase status"
echo "   sqlite3 /path/to/test.db '.schema' > /tmp/test_schema.txt"
echo ""
echo "2. На Stage-сервере выполни:"
echo "   cd /opt/campus_helper_liquibase_stage"
echo "   liquibase status"
echo "   sqlite3 /path/to/stage.db '.schema' > /tmp/stage_schema.txt"
echo ""
echo "3. На Prod-сервере выполни:"
echo "   cd /opt/campus_helper_liquibase_prod"
echo "   liquibase status"
echo "   sqlite3 /path/to/prod.db '.schema' > /tmp/prod_schema.txt"
echo ""
echo "4. Сравни схемы:"
echo "   diff /tmp/test_schema.txt /tmp/stage_schema.txt"
echo "   diff /tmp/stage_schema.txt /tmp/prod_schema.txt"
echo ""
echo "Или через Liquibase diff (если БД доступны с одной машины):"
echo "   liquibase diff --reference-url=jdbc:sqlite:/path/to/test.db --reference-username= --reference-password="
echo "   (в liquibase.properties указан url к Stage/Prod)"
echo ""
echo "Ожидаемый результат: схемы идентичны (все таблицы: users, settings, audit_log, medicine_new)"
