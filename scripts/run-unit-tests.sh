#!/bin/sh
# Лабораторная работа 7 — запуск юнит-тестов в TeamCity

set -e

echo "=== Установка зависимостей ==="
apt-get update -y
apt-get install -y qt5-qmake qtbase5-dev build-essential libqt5sql5-sqlite

echo "=== Переход в папку тестов ==="
cd "$(dirname "$0")/.." || true
if [ ! -f tests/campus_helper_tests.pro ]; then
  echo "ERROR: tests/campus_helper_tests.pro not found"
  exit 1
fi

echo "=== Сборка тестов ==="
cd tests
rm -f Makefile *.o moc_* campus_helper_tests
qmake campus_helper_tests.pro
make

echo "=== Запуск юнит-тестов ==="
./campus_helper_tests -o results.xml,xml -o -,txt
EXIT_CODE=$?

echo "=== Результат: exit code $EXIT_CODE ==="
exit $EXIT_CODE
