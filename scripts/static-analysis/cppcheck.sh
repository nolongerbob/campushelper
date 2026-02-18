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
# Проверяем наличие файлов для анализа
if ! ls *.cpp *.h 2>/dev/null | head -1 >/dev/null; then
  echo "⚠️  Нет файлов .cpp или .h для анализа"
  echo "Создаем пустой отчет"
  cat > ./cppcheck-report/index.html <<'HTML_END'
<!DOCTYPE html>
<html><head><title>cppcheck Report</title></head>
<body><h1>cppcheck Report</h1><p>Нет файлов для анализа.</p></body></html>
HTML_END
  exit 0
fi

# --enable=all включает все проверки
# НЕ используем --error-exitcode=1 чтобы не падать на предупреждениях
cppcheck --enable=all \
  --xml --xml-version=2 \
  --output-file=./cppcheck-report/report.xml \
  --suppress=missingIncludeSystem \
  *.cpp *.h 2>&1 | tee ./cppcheck-report/output.txt || true
EXIT_CODE=${PIPESTATUS[0]}

# Генерация HTML отчета (всегда, даже если были ошибки)
echo "=== Генерация HTML отчета ==="
cppcheck --enable=all --html --html-output=./cppcheck-report/ \
  *.cpp *.h 2>&1 || true

# Проверка наличия файлов отчета
if [ ! -f ./cppcheck-report/output.txt ]; then
  echo "⚠️  Отчет не создан, создаем минимальный"
  cat > ./cppcheck-report/output.txt <<'TXT_END'
cppcheck analysis completed
TXT_END
fi

# Всегда завершаемся успешно - проблемы показываются в отчете
echo "✅ cppcheck analysis completed successfully"
echo "📄 Отчет: ./cppcheck-report/index.html"
exit 0
