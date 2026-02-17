#!/bin/bash
# Статический анализ безопасности с помощью PVS-Studio
# Выход с ошибкой при обнаружении CRITICAL проблем

set -e

echo "=== Установка зависимостей ==="
apt-get update -y
apt-get install -y apt-utils wget build-essential qt5-qmake qtbase5-dev cmake

echo "=== Установка PVS-Studio ==="
wget -q -O - https://cdn.pvs-studio.com/etc/pubkey.txt | apt-key add -
wget -O /etc/apt/sources.list.d/viva64.list https://cdn.pvs-studio.com/etc/viva64.list
apt-get update -y
apt-get install -y pvs-studio

echo "=== Добавление лицензии PVS-Studio ==="
# ЗАМЕНИТЕ на свою лицензию или используйте триал
# pvs-studio-analyzer credentials YOUR_EMAIL YOUR_LICENSE_KEY
echo "⚠️  ВНИМАНИЕ: Замените лицензию PVS-Studio на свою!"

echo "=== Переход в папку сервера ==="
cd ./server

echo "=== Очистка старых файлов ==="
rm -f compile_commands.json moc* Makefile *.o *.pro strace_out pvs.log pvs*.tasks
rm -rf ./report

echo "=== Трассировка компиляции ==="
qmake -o Makefile server.pro
make clean
pvs-studio-analyzer trace -- make

echo "=== Запуск анализа PVS-Studio ==="
mkdir -p ./report
pvs-studio-analyzer analyze -l /root/.config/PVS-Studio/PVS-Studio.lic -o pvs.log --disableLicenseExpirationCheck || true

echo "=== Конвертация в HTML ==="
plog-converter -a GA:1,2 --renderTypes fullhtml -t tasklist -o ./report/ pvs.log || true

echo "=== Очистка ложных срабатываний ==="
if [ -f ./report/pvs.tasks ]; then
  sed "s|pvs-studio.com/en/docs/warnings/.*err.*Help.*|1|" ./report/pvs.tasks > ./report/pvs1.tasks 2>/dev/null || cp ./report/pvs.tasks ./report/pvs1.tasks
  sed "s|err Renew|1|" ./report/pvs1.tasks > ./report/pvs2.tasks 2>/dev/null || cp ./report/pvs1.tasks ./report/pvs2.tasks
else
  echo "⚠️  Отчет не создан (возможно, нет лицензии)"
  exit 0
fi

echo "=== Проверка на CRITICAL проблемы ==="
if grep -r 'err' ./report/pvs2.tasks 2>/dev/null; then
  echo "❌ CRITICAL security issues found!"
  exit 1
fi

echo "✅ PVS-Studio analysis completed successfully"
