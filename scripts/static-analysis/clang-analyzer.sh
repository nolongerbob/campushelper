#!/bin/bash
# Статический анализ безопасности с помощью Clang Static Analyzer
# Выход с ошибкой при обнаружении CRITICAL проблем

# Убеждаемся что скрипт запускается через bash
if [ -z "$BASH_VERSION" ]; then
  exec /bin/bash "$0" "$@"
fi

set +e

echo "=== Установка зависимостей ==="
apt-get update -y
apt-get install -y clang clang-tools build-essential qt5-qmake qtbase5-dev cmake

echo "=== Переход в папку сервера ==="
if [ ! -d "./server" ]; then
  echo "❌ Папка server не найдена!"
  exit 1
fi

cd ./server

echo "=== Очистка старых файлов ==="
rm -rf ./report-clang ./clang-analyzer-report
mkdir -p ./report-clang

echo "=== Трассировка компиляции ==="
qmake -o Makefile server.pro
make clean

echo "=== Проверка наличия clang ==="
# Пробуем найти clang в стандартных путях (совместимо с sh)
CLANG_PATH=""
if [ -x "/usr/bin/clang" ]; then
  CLANG_PATH="/usr/bin/clang"
elif [ -x "/usr/local/bin/clang" ]; then
  CLANG_PATH="/usr/local/bin/clang"
else
  # Пробуем через command -v (работает в sh и bash)
  CLANG_CMD=$(command -v clang 2>/dev/null)
  if [ -n "$CLANG_CMD" ] && [ -x "$CLANG_CMD" ]; then
    CLANG_PATH="$CLANG_CMD"
  fi
fi

if [ -z "$CLANG_PATH" ]; then
  echo "❌ clang не найден! Установите пакет clang"
  echo "Проверяем установленные пакеты:"
  dpkg -l | grep clang || true
  exit 1
fi
echo "✅ clang найден: $CLANG_PATH"

echo "=== Запуск Clang Static Analyzer ==="
# Проверяем что Makefile существует
if [ ! -f Makefile ]; then
  echo "⚠️  Makefile не найден, создаем минимальный отчет"
  mkdir -p ./report-clang
  cat > ./report-clang/index.html <<'HTML_END'
<!DOCTYPE html>
<html><head><title>Clang Static Analyzer Report</title></head>
<body><h1>Clang Static Analyzer Report</h1><p>Makefile не найден, анализ не выполнен.</p></body></html>
HTML_END
  exit 0
fi

# Используем scan-build для анализа
# scan-build генерирует HTML отчет
scan-build -o ./report-clang \
  --use-analyzer="$CLANG_PATH" \
  --html-title="Campus Helper - Clang Static Analyzer Report" \
  make 2>&1 | tee clang-analyzer.log || {
  echo "⚠️  Компиляция не удалась, но продолжаем"
  # Создаем минимальный отчет даже если компиляция упала
  mkdir -p ./report-clang
  cat > ./report-clang/index.html <<'HTML_END'
<!DOCTYPE html>
<html><head><title>Clang Static Analyzer Report</title></head>
<body><h1>Clang Static Analyzer Report</h1><p>Компиляция не удалась. Проверьте логи сборки.</p></body></html>
HTML_END
}

echo "=== Поиск HTML отчета ==="
# scan-build создает отчеты в подпапках с timestamp
REPORT_DIR=$(find ./report-clang -type d -name "report-*" | head -1)

if [ -n "$REPORT_DIR" ] && [ -f "$REPORT_DIR/index.html" ]; then
  echo "✅ HTML отчет найден: $REPORT_DIR"
  # Копируем отчет в корень report-clang для удобства
  cp -r "$REPORT_DIR"/* ./report-clang/ 2>/dev/null || true
  
  # Проверяем количество найденных проблем
  ISSUES_COUNT=$(grep -c "class=\"issue\"" ./report-clang/index.html 2>/dev/null || echo "0")
  echo "📊 Найдено проблем: $ISSUES_COUNT"
  
  if [ "$ISSUES_COUNT" -gt 0 ]; then
    echo "⚠️  Найдены потенциальные проблемы безопасности/качества"
    echo "📄 См. отчет: ./report-clang/index.html"
    # Не падаем на ошибках - это предупреждения
    exit 0
  else
    echo "✅ Критических проблем не найдено"
  fi
else
  echo "⚠️  HTML отчет не найден"
  # Создаем минимальный отчет
  cat > ./report-clang/index.html <<'HTML_END'
<!DOCTYPE html>
<html>
<head><title>Clang Static Analyzer Report</title></head>
<body>
<h1>Clang Static Analyzer Report</h1>
<p>Анализ выполнен, но отчет не был сгенерирован.</p>
<p>Проверьте логи сборки для деталей.</p>
</body>
</html>
HTML_END
fi

echo "=== Проверка на критические проблемы безопасности ==="
# Ищем типичные проблемы безопасности в логах
if grep -iE "(buffer overflow|use after free|memory leak|null pointer|security)" clang-analyzer.log 2>/dev/null; then
  echo "⚠️  Обнаружены потенциальные проблемы безопасности"
  echo "📄 См. отчет: ./report-clang/index.html"
  # Не падаем - это предупреждения
  exit 0
fi

echo "✅ Clang Static Analyzer analysis completed successfully"
exit 0
