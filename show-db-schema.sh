#!/bin/bash
# Вывести схему БД через Docker

set -e

echo "=== Пересоздание БД с нуля ==="
sudo docker compose down -v
sudo docker compose up -d --build

echo ""
echo "=== Ожидание запуска контейнера ==="
sleep 5

echo ""
echo "=== Список таблиц ==="
sudo docker compose run --rm db-shell ".tables"

echo ""
echo "=== Полная схема БД ==="
sudo docker compose run --rm db-shell ".schema"

echo ""
echo "=== Схема каждой таблицы ==="
sudo docker compose run --rm db-shell ".schema users"
sudo docker compose run --rm db-shell ".schema settings"
sudo docker compose run --rm db-shell ".schema audit_log" 2>/dev/null || echo "Таблица audit_log ещё не создана (нужно применить миграции Liquibase)"

echo ""
echo "=== Данные из users ==="
sudo docker compose run --rm db-shell "SELECT * FROM users;"
