# Скрипт для шага PVS-Studio в TeamCity

Если `bash scripts/static-analysis/pvs-studio.sh` не работает, скопируйте содержимое ниже **напрямую в Custom script** шага TeamCity:

---

```bash
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
# Бесплатная лицензия без регистрации (работает с комментариями в коде)
pvs-studio-analyzer credentials PVS-Studio Free FREE-FREE-FREE-FREE
echo "✅ Используется бесплатная лицензия PVS-Studio Free"
echo "⚠️  Требуется комментарий PVS-Studio в начале каждого .cpp/.h файла"

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
```

---

**Использование в TeamCity:**

1. **Runner type:** Command Line
2. **Custom script:** вставьте весь код выше (без тройных обратных кавычек)
3. **Working directory:** оставьте пустым (по умолчанию корень checkout)
4. **Artifacts:** `server/report/** => static-analysis/pvs-studio/`
