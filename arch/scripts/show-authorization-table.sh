#!/bin/bash
# Вывод данных из таблицы authorization через контейнер sqlite3
# Сервер должен хотя бы раз быть запущен (docker compose up -d server), чтобы создалась БД
cd "$(dirname "$0")/.."
docker compose run --rm sqlite3 /data/campus_helper.db "SELECT * FROM authorization;"
