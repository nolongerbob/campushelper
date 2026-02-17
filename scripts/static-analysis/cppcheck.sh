#!/bin/bash
# Статический анализ качества кода с помощью cppcheck
# Выход с ошибкой при обнаружении BLOCKER проблем

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
if command -v cppcheck-htmlreport &> /dev/null; then
  cppcheck-htmlreport --file=./cppcheck-report/report.xml --report-dir=./cppcheck-report/ --source-dir=. || true
else
  echo "⚠️  cppcheck-htmlreport не найден, создаём простой HTML"
  # Создаём простой index.html с информацией
  cat > ./cppcheck-report/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html>
<head><title>cppcheck Report</title></head>
<body>
<h1>cppcheck Analysis Report</h1>
<p>Проверка завершена. Результаты в <a href="report.xml">report.xml</a> и <a href="output.txt">output.txt</a></p>
<h2>Вывод cppcheck:</h2>
<pre>
HTMLEOF
  cat ./cppcheck-report/output.txt >> ./cppcheck-report/index.html 2>/dev/null || echo "Нет вывода" >> ./cppcheck-report/index.html
  echo "</pre></body></html>" >> ./cppcheck-report/index.html
fi

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
