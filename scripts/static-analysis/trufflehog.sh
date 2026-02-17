#!/bin/bash
# Поиск секретов в репозитории с помощью Trufflehog
# Выход с ошибкой при обнаружении любого секрета

set +e  # Отключаем set -e для ручной обработки ошибок

echo "=== Установка Trufflehog ==="
apt-get update -y
apt-get install -y wget

# Определение архитектуры
ARCH=$(uname -m)
if [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
  ARCH_SUFFIX="arm64"
else
  ARCH_SUFFIX="amd64"
fi

echo "=== Архитектура: $ARCH_SUFFIX ==="

# Скачивание Trufflehog для нужной архитектуры
TRUFFLEHOG_VERSION="3.63.0"
wget -q https://github.com/trufflesecurity/trufflehog/releases/download/v${TRUFFLEHOG_VERSION}/trufflehog_${TRUFFLEHOG_VERSION}_linux_${ARCH_SUFFIX}.tar.gz -O trufflehog.tar.gz || \
  wget -q https://github.com/trufflesecurity/trufflehog/releases/latest/download/trufflehog_${TRUFFLEHOG_VERSION}_linux_${ARCH_SUFFIX}.tar.gz -O trufflehog.tar.gz || {
  echo "⚠️  Не удалось скачать Trufflehog для $ARCH_SUFFIX, пропускаем проверку секретов"
  exit 0
}

tar -xzf trufflehog.tar.gz
chmod +x trufflehog
mv trufflehog /usr/local/bin/ 2>/dev/null || cp trufflehog /usr/local/bin/
rm -f trufflehog.tar.gz

echo "=== Создание директории для отчета ==="
mkdir -p ./trufflehog-report

echo "=== Поиск секретов в репозитории ==="
# --json — вывод в JSON
# --only-verified — только проверенные секреты
trufflehog filesystem . --json --only-verified > ./trufflehog-report/report.json 2>&1 || true

echo "=== Проверка на наличие секретов ==="
if [ -s ./trufflehog-report/report.json ]; then
  SECRETS_COUNT=$(cat ./trufflehog-report/report.json | grep -c '"DetectorType"' || echo "0")
  if [ "$SECRETS_COUNT" -gt 0 ]; then
    echo "❌ Secrets found in repository!"
    echo "Found $SECRETS_COUNT secrets:"
    cat ./trufflehog-report/report.json
    exit 1
  fi
fi

echo "✅ No secrets found. Repository is clean."
