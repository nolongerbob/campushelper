#!/bin/bash
# Статический анализ качества кода с помощью cppcheck
# Выход с ошибкой при обнаружении BLOCKER проблем

set -e

echo "=== Установка cppcheck ==="
apt-get update -y
apt-get install -y cppcheck

echo "=== Переход в папку сервера ==="
cd ./server

echo "=== Очистка старых отчетов ==="
rm -rf ./cppcheck-report
mkdir -p ./cppcheck-report

echo "=== Запуск анализа cppcheck ==="
# --enable=all включает все проверки
# --error-exitcode=1 — выход с ошибкой при обнаружении проблем
cppcheck --enable=all --error-exitcode=1 \
  --xml --xml-version=2 \
  --output-file=./cppcheck-report/report.xml \
  --suppress=missingIncludeSystem \
  *.cpp *.h 2>&1 | tee ./cppcheck-report/output.txt || EXIT_CODE=$?

# Проверка на BLOCKER (критические ошибки)
if grep -iE "error|warning" ./cppcheck-report/output.txt | grep -iE "blocker|critical"; then
  echo "❌ BLOCKER issues found!"
  exit 1
fi

# Генерация HTML отчета (даже если были ошибки)
echo "=== Генерация HTML отчета ==="
cppcheck --enable=all --html --html-output=./cppcheck-report/ \
  *.cpp *.h 2>&1 || true

if [ "${EXIT_CODE:-0}" -ne 0 ]; then
  echo "❌ cppcheck found issues (exit code: $EXIT_CODE)"
  exit 1
fi

echo "✅ cppcheck analysis completed successfully"
