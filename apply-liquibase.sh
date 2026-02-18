#!/bin/bash
# Применить миграции Liquibase к БД в Docker

set -e

VOLUME_NAME=$(docker volume ls | grep -E 'documents_db-data|.*_db-data' | head -1 | awk '{print $2}')
if [ -z "$VOLUME_NAME" ]; then
  echo "Volume не найден. Запусти сначала: docker compose up -d"
  exit 1
fi

echo "=== Применение миграций Liquibase к БД в volume: $VOLUME_NAME ==="

docker run --rm \
  -v "$VOLUME_NAME:/app" \
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
    java -jar liquibase.jar \
      --driver=org.sqlite.JDBC \
      --url=jdbc:sqlite:/app/campus_helper.db \
      --changeLogFile=/changelog/db.changelog-master.xml \
      update
  "

echo "=== Миграции применены. Проверь: docker compose run --rm db-shell .schema ==="
