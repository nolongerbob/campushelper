# Демонстрация изменений в коде (ЛР5 п.6)

## GitFlow: структура веток и коммитов

```
main (production)
  ↑
dev (development) ← текущая ветка после merge PR
  ↑
feature/lab5-pr (feature branch) ← PR в dev
```

**Коммиты в dev:**
- `6f20b28` — Клиент: настройка адреса сервера через CAMPUS_HELPER_SERVER_HOST
- `e17ee76` — Merge branch 'feature/lab5-pr' into dev
- `d53880e` — CI: убрать проброс порта 45454 из docker-compose.yml
- `f4463eb` — ЛР5 п.5: ветка для PR в dev, требование согласования

---

## Изменённые файлы

### Новые файлы

1. **`arch/client/config.h`** — конфигурация адреса сервера
2. **`CLIENT_STAGE_SETUP.md`** — инструкция по подключению к stage
3. **`client/`** — копия клиента в корне для сборки

### Изменённые файлы

1. **`arch/client/logindialog.cpp`** — использование `getServerHost()` вместо `127.0.0.1`
2. **`arch/client/mainwindow.cpp`** — использование `getServerHost()` для подключения
3. **`arch/client/client.pro`** — добавлен `config.h` в HEADERS
4. **`docker-compose.yml`** — убран проброс порта 45454 (для CI)

---

## Конкретные изменения в коде

### 1. Новый файл: `arch/client/config.h`

```cpp
// Адрес stage-сервера через переменную окружения CAMPUS_HELPER_SERVER_HOST
inline QString getServerHost() {
    const QByteArray envHost = qgetenv("CAMPUS_HELPER_SERVER_HOST");
    if (!envHost.isEmpty())
        return QString::fromUtf8(envHost);
    return QStringLiteral("127.0.0.1");  // localhost по умолчанию
}
constexpr quint16 SERVER_PORT = 45454;
```

### 2. Изменение в `logindialog.cpp`

**Было:**
```cpp
socket.connectToHost(QHostAddress(QStringLiteral("127.0.0.1")), 45454);
```

**Стало:**
```cpp
#include "config.h"
...
socket.connectToHost(QHostAddress(getServerHost()), SERVER_PORT);
```

### 3. Изменение в `mainwindow.cpp`

**Было:**
```cpp
void MainWindow::connectToServer() {
    m_socket->connectToHost(QStringLiteral("127.0.0.1"), 45454);
}
void MainWindow::onAddUserTriggered() {
    AddUserDialog dlg(QStringLiteral("127.0.0.1"), 45454, this);
}
```

**Стало:**
```cpp
#include "config.h"
...
void MainWindow::connectToServer() {
    m_socket->connectToHost(getServerHost(), SERVER_PORT);
}
void MainWindow::onAddUserTriggered() {
    AddUserDialog dlg(getServerHost(), SERVER_PORT, this);
}
```

### 4. Изменение в `docker-compose.yml` (CI)

**Было:**
```yaml
services:
  server:
    ...
    ports:
      - "45454:45454"  # конфликт порта в CI
```

**Стало:**
```yaml
services:
  server:
    ...
    # Порт не пробрасываем в CI — контейнер только проверяется на запуск
    # Порт 45454 используется только в docker-compose.stage.yml для реального stage-сервера
```

---

## Статистика изменений

```
9 files changed, 362 insertions(+), 4 deletions(-)
```

**Добавлено:**
- Конфигурация адреса сервера через переменную окружения
- Поддержка подключения к stage-серверу
- Исправления для CI/CD (убраны конфликты портов)

---

## Использование

### Подключение к stage-серверу

На test-клиенте:

```bash
export CAMPUS_HELPER_SERVER_HOST=IP_STAGE_СЕРВЕРА
./client
```

Например:
```bash
export CAMPUS_HELPER_SERVER_HOST=10.211.55.5
./client
```

---

## Pull Request

**PR #1:** `feature/lab5-pr` → `dev`
- Создан для ЛР5 п.5
- Требуется согласование другого члена команды
- После merge изменения попали в `dev`
- Из `dev` можно собрать и развернуть на stage

---

## Результат

✅ Все изменения в коде зафиксированы в Git  
✅ Pull Request создан и смержен в `dev`  
✅ Клиент может подключаться к stage-серверу через переменную окружения  
✅ CI/CD работает без конфликтов портов и контейнеров  
✅ Сборка из ветки `dev` успешна в TeamCity
