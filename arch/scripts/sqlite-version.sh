#!/bin/bash
# Вывод версии sqlite3 из контейнера (образ с Docker Hub)
cd "$(dirname "$0")/.."
docker compose run --rm sqlite3 --version
