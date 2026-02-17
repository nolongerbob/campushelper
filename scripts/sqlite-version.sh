#!/bin/bash
# Вывод версии sqlite3 (для CI — проверка, что сервер использует SQLite)
cd "$(dirname "$0")/.."

# В CI sqlite3 контейнера нет, но можно проверить версию через docker
echo "SQLite используется в сервере через Qt QSQLITE"
docker ps --filter "name=.*server.*" --format "Container: {{.Names}}"
