#!/bin/sh
# Запуск docker-compose в CI без конфликта имён контейнеров.
# Удаляем старый контейнер (если есть) и поднимаем с уникальным проектом.

set -e
COMPOSE_FILE="${1:-docker-compose.yml}"
PROJECT_NAME="${2:-build${TEAMCITY_BUILD_NUMBER:-$$}}"

docker rm -f campus-helper-server 2>/dev/null || true
docker compose -p "$PROJECT_NAME" -f "$COMPOSE_FILE" up -d
