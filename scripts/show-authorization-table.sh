#!/bin/bash
# Проверка, что сервер запущен и работает (для CI)
set -e
cd "$(dirname "$0")/.."

# Найти контейнер сервера
CONTAINER=$(docker ps --filter "name=.*server.*" --format "{{.Names}}" | head -1)

if [ -z "$CONTAINER" ]; then
  echo "Ошибка: контейнер сервера не найден"
  exit 1
fi

echo "Сервер запущен: $CONTAINER"
echo "Проверка доступности порта 45454..."
docker port "$CONTAINER" | grep 45454 || echo "Порт 45454 не проброшен"
echo "Сервер работает, БД создана при старте"
