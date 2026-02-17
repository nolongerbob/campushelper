# Демонстрация изменений в коде (ЛР5)

## Структура веток (GitFlow)

```
main (production)
  ↑
dev (development)
  ↑
feature/lab5-pr (feature branch)
```

**Ветки:**
- **main** — основная ветка (production)
- **dev** — ветка разработки (development)
- **feature/lab5-pr** — feature-ветка для ЛР5 п.5 (Pull Request)

---

## История коммитов

### Ветка dev (после merge feature/lab5-pr)

1. **6f20b28** — Клиент: настройка адреса сервера через CAMPUS_HELPER_SERVER_HOST для подключения к stage
2. **e17ee76** — Merge branch 'feature/lab5-pr' into dev
3. **d53880e** — CI: убрать проброс порта 45454 из docker-compose.yml — убрать конфликт порта в TeamCity
4. **03a4695** — Merge pull request #1 from nolongerbob/feature/lab5-pr
5. **f4463eb** — ЛР5 п.5: ветка для PR в dev, требование согласования

### Основные изменения для CI/CD

- **1d133c0** — CI: скрипты в корне для шагов TeamCity
- **e49485c** — CI: убрать sqlite3 из docker-compose.yml
- **c16d7cf** — CI: папка server в корне для шага Docker в TeamCity
- **b08ecee** — CI: скрипт ci/run-compose.sh
- **e368967** — README: инструкция для устранения конфликта контейнеров

---

## Изменённые файлы (main → dev)

### Новые файлы

- **CLIENT_STAGE_SETUP.md** — инструкция по подключению клиента к stage-серверу
- **arch/client/config.h** — конфигурация адреса сервера (переменная окружения)
- **client/** — копия клиента в корне для сборки

### Изменённые файлы

- **arch/client/client.pro** — добавлен config.h в HEADERS
- **arch/client/logindialog.cpp** — использование `getServerHost()` вместо `127.0.0.1`
- **arch/client/mainwindow.cpp** — использование `getServerHost()` для подключения к серверу
- **docker-compose.yml** — убран проброс порта 45454 (для CI, чтобы избежать конфликта)

---

## Ключевые изменения в коде

### 1. Конфигурация адреса сервера (`arch/client/config.h`)

```cpp
// Адрес stage-сервера: можно задать через переменную окружения CAMPUS_HELPER_SERVER_HOST
// По умолчанию: localhost (для локальной разработки)
inline QString getServerHost() {
    const QByteArray envHost = qgetenv("CAMPUS_HELPER_SERVER_HOST");
    if (!envHost.isEmpty())
        return QString::fromUtf8(envHost);
    return QStringLiteral("127.0.0.1");  // localhost по умолчанию
}
```

### 2. Изменение в `logindialog.cpp`

**Было:**
```cpp
socket.connectToHost(QHostAddress(QStringLiteral("127.0.0.1")), 45454);
```

**Стало:**
```cpp
socket.connectToHost(QHostAddress(getServerHost()), SERVER_PORT);
```

### 3. Изменение в `mainwindow.cpp`

**Было:**
```cpp
void MainWindow::connectToServer() {
    m_socket->connectToHost(QStringLiteral("127.0.0.1"), 45454);
}
```

**Стало:**
```cpp
void MainWindow::connectToServer() {
    m_socket->connectToHost(getServerHost(), SERVER_PORT);
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

## Использование для подключения к stage

На test-клиенте задайте переменную окружения перед запуском:

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

---

## Статистика изменений

```
9 files changed, 362 insertions(+), 4 deletions(-)
```

**Основные добавления:**
- Конфигурация адреса сервера через переменную окружения
- Поддержка подключения к stage-серверу
- Исправления для CI/CD (убраны конфликты портов и контейнеров)
