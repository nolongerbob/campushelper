#!/bin/sh
# Установка Liquibase без snap (использует системную Java).
# Сначала удали snap: sudo snap remove liquibase
# Запуск: ./scripts/install-liquibase-local.sh

set -e

LB_VERSION="4.24.0"
LB_DIR="${HOME}/opt/liquibase"

echo "=== Создание каталога $LB_DIR ==="
mkdir -p "$LB_DIR"
cd "$LB_DIR"

echo "=== Загрузка Liquibase ${LB_VERSION} ==="
if [ ! -f "liquibase" ]; then
  wget -q "https://github.com/liquibase/liquibase/releases/download/v${LB_VERSION}/liquibase-${LB_VERSION}.tar.gz" -O "liquibase-${LB_VERSION}.tar.gz"
  tar -xzf "liquibase-${LB_VERSION}.tar.gz"
  rm -f "liquibase-${LB_VERSION}.tar.gz"
fi

if [ ! -x "liquibase" ]; then
  echo "ERROR: $LB_DIR/liquibase не найден"
  exit 1
fi

echo "=== Готово ==="
echo "Добавь в ~/.bashrc (или выполни в текущей сессии):"
echo "  export PATH=\"\$HOME/opt/liquibase:\$PATH\""
echo "  export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-arm64"
echo ""
echo "Потом выполни: source ~/.bashrc  и  liquibase --version"
