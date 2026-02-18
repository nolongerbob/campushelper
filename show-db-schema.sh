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
echo "=== Применение миграций Liquibase ==="
VOLUME_NAME=$(sudo docker volume ls | grep -E 'documents_db-data|.*_db-data' | head -1 | awk '{print $2}')
if [ -n "$VOLUME_NAME" ]; then
  sudo docker run --rm \
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
      LIQUIBASE_JAR=\$(find /tmp -name 'liquibase.jar' -o -name 'liquibase-*.jar' | head -1)
      java -jar \"\$LIQUIBASE_JAR\" \
        --driver=org.sqlite.JDBC \
        --url=jdbc:sqlite:/app/campus_helper.db \
        --changeLogFile=/changelog/db.changelog-master.xml \
        update
    " 2>&1
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
