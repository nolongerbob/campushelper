#!/bin/sh
# Скрипт выполняется на PROD-сервере по SSH (TeamCity → Deploy to PROD).
# На Prod должны быть: Docker, docker-compose, Java, Liquibase, каталог с liquibase.properties и database/changelog.
# Пути PROD_DIR и LIQUIBASE_DIR задай под свой сервер (или через переменные TeamCity).

set -e

PROD_DIR="${PROD_DIR:-/opt/campus_helper_prod}"
LIQUIBASE_DIR="${LIQUIBASE_DIR:-/opt/campus_helper_liquibase_prod}"
DOCKER_IMAGE="${DOCKER_IMAGE:-danprog19/campus-helper-server:latest}"

echo "=== Деплой на PROD: остановка старого контейнера ==="
cd "$PROD_DIR"
docker compose -f docker-compose.prod.yml down || true

echo "=== Pull образа ==="
docker pull "$DOCKER_IMAGE"

echo "=== Запуск контейнера ==="
export DOCKER_IMAGE
docker compose -f docker-compose.prod.yml up -d

echo "=== Ожидание запуска ==="
sleep 5

echo "=== Сверка схемы БД на PROD (Liquibase) ==="
cd "$LIQUIBASE_DIR"
liquibase update
liquibase status

echo "=== Деплой на PROD завершён ==="
