# Создание отдельного пайплайна для PROD (ЛР8, пункт 6)

Создать отдельную Build Configuration в TeamCity для развертывания на PROD-сервере, идентичную пайплайну для DEV, но с подключением к Prod и сверкой схем БД.

---

## Шаг 1. Создать новую Build Configuration для PROD

1. В TeamCity открой свой проект.
2. Нажми **"Create build configuration"** (или **"+"** рядом с существующими конфигурациями).
3. **Name:** `Deploy PROD` (или любое понятное имя).
4. **Build configuration ID:** `Deploy_PROD` (автоматически или вручную).
5. Нажми **Create**.

---

## Шаг 2. Настроить VCS Root (репозиторий)

1. В новой конфигурации **Deploy PROD** открой **VCS Settings** (или **Version Control Settings**).
2. Добавь тот же VCS root, что и в DEV-конфигурации (GitHub/GitLab и т.д.).
3. **Branch specification:** укажи ветку для PROD (например, `main`, `master`, или `refs/heads/prod`).
   - Обычно для PROD используется стабильная ветка (`main`/`master`), а не `dev`.
4. Сохрани.

---

## Шаг 3. Скопировать шаги из DEV-конфигурации

1. Открой **DEV-конфигурацию** (ту, что деплоит на Stage).
2. Зайди в **Build Steps**.
3. Посмотри, какие шаги там есть (например: Build, Docker Build, Docker Push, SSH Deploy to Stage и т.д.).
4. Вернись в **Deploy PROD** → **Build Steps**.
5. Добавь те же шаги, что в DEV, но:
   - **Docker Build** — оставь как есть (собирает образ).
   - **Docker Push** — оставь как есть (пушит в Docker Hub).
   - **SSH Deploy** — замени на шаг для **Prod** (см. Шаг 4 ниже).

Или проще: в TeamCity можно **клонировать Build Configuration**:
- В DEV-конфигурации: **Actions** → **Clone build configuration**.
- Назови клон **"Deploy PROD"**.
- Затем измени в нём SSH-шаг на Prod (см. Шаг 4).

---

## Шаг 4. Добавить SSH-шаг развертывания на Prod с Liquibase

В **Deploy PROD** → **Build Steps**:

1. Найди шаг **"Deploy to Stage"** (если клонировал из DEV) или создай новый.
2. Измени его настройки:
   - **Step name:** `Deploy to PROD`.
   - **SSH connection:** подключение к **Prod-серверу** (host, user, key — другие, чем для Stage).
3. В поле **Script** / **Commands** вставь **весь скрипт ниже**:

```bash
#!/bin/sh
set -e

echo "=== Деплой на PROD: остановка старого контейнера ==="
cd /opt/campus_helper_prod  # путь на Prod, где лежит docker-compose.prod.yml
docker compose -f docker-compose.prod.yml down || true

echo "=== Pull нового образа из Docker Hub ==="
export DOCKER_IMAGE=danprog19/campus-helper-server:%build.number%  # или latest, или переменная TeamCity
docker pull "$DOCKER_IMAGE" || docker pull danprog19/campus-helper-server:latest

echo "=== Запуск нового контейнера ==="
docker compose -f docker-compose.prod.yml up -d

echo "=== Ожидание запуска контейнера ==="
sleep 5

echo "=== Сверка схемы БД на PROD через Liquibase (ЛР8) ==="
cd /opt/campus_helper_liquibase_prod  # каталог на Prod с liquibase.properties (url на Prod-БД)
liquibase update
liquibase status

echo "=== Деплой на PROD завершён ==="
```

4. Замени пути:
   - `/opt/campus_helper_prod` → путь на Prod, где лежит `docker-compose.prod.yml` (или `docker-compose.yml`).
   - `/opt/campus_helper_liquibase_prod` → путь на Prod, где лежит Liquibase-проект с `liquibase.properties` (url на Prod-БД).
   - `danprog19/campus-helper-server` → твой Docker Hub репозиторий.
   - `%build.number%` → если используешь теги, иначе убери или замени на `latest`.
5. Сохрани шаг (**Save**).

---

## Шаг 5. Настроить триггеры для PROD

В **Deploy PROD** → **Triggers**:

- **VCS trigger:** обычно для PROD запуск вручную или по тегу (не автоматически при каждом коммите).
- Или **Schedule trigger:** запуск по расписанию (например, раз в неделю).
- Или **Build trigger:** запуск после успешной сборки DEV/Stage (после тестирования).

Рекомендация: для PROD лучше **ручной запуск** или **по тегу** (например, `v1.0.0`), чтобы не деплоить каждое изменение автоматически.

---

## Шаг 6. Подготовка на Prod-сервере (один раз)

На Prod-сервере должно быть то же самое, что на Stage (см. `ЧТО_СДЕЛАТЬ_ЧТОБЫ_РАБОТАЛО.md`, пункт 1):

1. Установлены **Java** и **Liquibase**.
2. Создан каталог `/opt/campus_helper_liquibase_prod` (или другой путь).
3. В нём лежат:
   - `liquibase.properties` с подключением к **Prod-БД** (url, username, password для Prod).
   - `database/changelog/` — файлы миграций (из репозитория).
4. Проверка: с Prod выполни `cd /opt/campus_helper_liquibase_prod && liquibase update` — должно работать без ошибок.

---

## Чек-лист

- [ ] Создана Build Configuration **"Deploy PROD"** в TeamCity.
- [ ] Настроен VCS root (репозиторий) с веткой для PROD (например, `main`).
- [ ] Скопированы шаги из DEV (Build, Docker Build, Docker Push) или клонирована конфигурация.
- [ ] Добавлен SSH-шаг **"Deploy to PROD"** с подключением к Prod-серверу.
- [ ] В SSH-шаге вставлен скрипт с Docker и Liquibase (см. Шаг 4).
- [ ] Пути в скрипте заменены на реальные пути на Prod-сервере.
- [ ] На Prod-сервере установлены Java, Liquibase, Docker.
- [ ] На Prod-сервере есть каталог Liquibase-проекта с `liquibase.properties` (url на Prod-БД) и `database/changelog/`.
- [ ] Настроены триггеры для PROD (ручной запуск или по тегу).
- [ ] Проверка: запуск сборки **"Deploy PROD"** в TeamCity — деплой и сверка схемы БД должны выполниться без ошибок.

---

## Кратко

- **Отдельный пайплайн для PROD** = новая Build Configuration в TeamCity с теми же шагами, что в DEV, но SSH-шаг подключается к Prod-серверу и выполняет деплой + `liquibase update` на Prod.
- На Prod-сервере должен быть настроен Liquibase-проект с `liquibase.properties`, указывающим на Prod-БД.
