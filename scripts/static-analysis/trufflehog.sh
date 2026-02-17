#!/bin/bash
# Поиск секретов в репозитории с помощью Trufflehog
# Выход с ошибкой при обнаружении любого секрета

set -e

echo "=== Установка Trufflehog ==="
apt-get update -y
apt-get install -y wget

# Скачивание последней версии Trufflehog
TRUFFLEHOG_VERSION="3.63.0"
wget https://github.com/trufflesecurity/trufflehog/releases/download/v${TRUFFLEHOG_VERSION}/trufflehog_${TRUFFLEHOG_VERSION}_linux_amd64.tar.gz || \
  wget https://github.com/trufflesecurity/trufflehog/releases/latest/download/trufflehog_${TRUFFLEHOG_VERSION}_linux_amd64.tar.gz

tar -xzf trufflehog_${TRUFFLEHOG_VERSION}_linux_amd64.tar.gz
chmod +x trufflehog
mv trufflehog /usr/local/bin/ || cp trufflehog /usr/local/bin/

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
