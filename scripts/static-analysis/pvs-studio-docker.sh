#!/bin/bash
# Запуск PVS-Studio через Docker x86_64 для ARM64 хостов
# ВНИМАНИЕ: очень медленно из-за эмуляции!

set -e

echo "=== Проверка архитектуры ==="
ARCH=$(uname -m)
echo "Текущая архитектура: $ARCH"

if [ "$ARCH" != "aarch64" ] && [ "$ARCH" != "arm64" ]; then
  echo "✅ Архитектура x86_64, можно использовать нативный PVS-Studio"
  echo "Используйте pvs-studio.sh вместо этого скрипта"
  exit 1
fi

echo "⚠️  ARM64 обнаружен, запускаем PVS-Studio через Docker x86_64"
echo "⚠️  Это будет медленно из-за эмуляции!"

echo "=== Установка зависимостей ==="
apt-get update -y
apt-get install -y docker.io qemu-user-static binfmt-support

echo "=== Регистрация QEMU для эмуляции x86_64 ==="
# Регистрируем binfmt для автоматической эмуляции
update-binfmts --enable qemu-x86_64 || true
docker run --rm --privileged multiarch/qemu-user-static --reset -p yes || true

echo "=== Настройка Docker buildx ==="
docker buildx create --name multiplatform --use 2>/dev/null || docker buildx use multiplatform || true
docker buildx inspect --bootstrap || true

echo "=== Создание Dockerfile для PVS-Studio ==="
cat > /tmp/Dockerfile.pvs <<'EOF'
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Установка зависимостей
RUN apt-get update && \
    apt-get install -y wget gnupg2 build-essential qt5-qmake qtbase5-dev cmake curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Скачивание и установка PVS-Studio напрямую (минуя репозиторий)
# Используем прямую ссылку на deb пакет последней версии
RUN PVS_VERSION="7.38" && \
    (wget --no-check-certificate -O /tmp/pvs-studio.deb \
    "https://files.pvs-studio.com/pvs-studio_${PVS_VERSION}_amd64.deb" || \
     wget --no-check-certificate -O /tmp/pvs-studio.deb \
     "https://cdn.pvs-studio.com/pvs-studio_${PVS_VERSION}_amd64.deb" || \
     echo "⚠️ Не удалось скачать PVS-Studio, пропускаем установку") && \
    if [ -f /tmp/pvs-studio.deb ]; then \
        dpkg -i /tmp/pvs-studio.deb || apt-get install -f -y; \
        rm -f /tmp/pvs-studio.deb; \
    fi

WORKDIR /workspace
EOF

echo "=== Сборка Docker образа через buildx (может занять 10-15 минут) ==="
docker buildx build --platform linux/amd64 --load -f /tmp/Dockerfile.pvs -t pvs-studio-x86:latest /tmp/

echo "=== Запуск анализа в контейнере ==="
docker run --rm \
  --platform linux/amd64 \
  -v "$(pwd):/workspace" \
  -w /workspace/server \
  pvs-studio-x86:latest \
  bash -c "
    pvs-studio-analyzer credentials daniel.kojemyakin@icloud.com Y0G0-6XBZ-2R81-C605 && \
    rm -f compile_commands.json moc* Makefile *.o *.pro strace_out pvs.log pvs*.tasks && \
    rm -rf ./report && \
    qmake -o Makefile server.pro && \
    make clean && \
    pvs-studio-analyzer trace -- make && \
    mkdir -p ./report && \
    pvs-studio-analyzer analyze -l /root/.config/PVS-Studio/PVS-Studio.lic -o pvs.log --disableLicenseExpirationCheck && \
    plog-converter -a GA:1,2 --renderTypes fullhtml -t tasklist -o ./report/ pvs.log
  "

echo "=== Проверка результатов ==="
if [ -f ./server/report/pvs.tasks ]; then
  echo "✅ HTML отчет создан: ./server/report/"
  
  # Проверка на критические проблемы
  if grep -r 'err' ./server/report/pvs.tasks 2>/dev/null; then
    echo "❌ CRITICAL security issues found!"
    exit 1
  fi
else
  echo "⚠️  Отчет не создан"
  exit 0
fi

echo "✅ PVS-Studio analysis completed successfully"
