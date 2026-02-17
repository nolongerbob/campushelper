#!/bin/bash
# Статический анализ качества кода с помощью cppcheck
# Выход с ошибкой при обнаружении BLOCKER проблем

# Убеждаемся что скрипт запускается через bash
if [ -z "$BASH_VERSION" ]; then
  exec /bin/bash "$0" "$@"
fi

set +e  # Отключаем set -e для ручной обработки ошибок

echo "=== Установка cppcheck ==="
apt-get update -y
apt-get install -y cppcheck || {
  echo "❌ Не удалось установить cppcheck"
  exit 1
}

echo "=== Переход в папку сервера ==="
if [ ! -d "./server" ]; then
  echo "❌ Папка server не найдена!"
  exit 1
fi
cd ./server || exit 1

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
  *.cpp *.h 2>&1 | tee ./cppcheck-report/output.txt
EXIT_CODE=$?

# Проверка на BLOCKER (критические ошибки)
if grep -iE "error|warning" ./cppcheck-report/output.txt 2>/dev/null | grep -iE "blocker|critical"; then
  echo "❌ BLOCKER issues found!"
  EXIT_CODE=1
fi

# Генерация HTML отчета (всегда, даже если были ошибки)
echo "=== Генерация HTML отчета ==="
cppcheck --enable=all --html --html-output=./cppcheck-report/ \
  *.cpp *.h 2>&1 || true

# Проверка наличия файлов отчета
if [ ! -f ./cppcheck-report/output.txt ]; then
  echo "⚠️  Отчет не создан"
  exit 0
fi

if [ "$EXIT_CODE" -ne 0 ]; then
  echo "❌ cppcheck found issues (exit code: $EXIT_CODE)"
  echo "Проверь отчет: ./cppcheck-report/output.txt"
  exit 1
fi

echo "✅ cppcheck analysis completed successfully"
exit 0
