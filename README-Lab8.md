# Лабораторная работа 8 — Схема БД, анализ SQL и миграции в CI/CD

## 1. Директория для актуальной схемы БД

В репозитории создана директория **`schema/`** для хранения актуальной схемы базы данных в виде SQL-файлов:

- `schema/001_initial.sql` — таблица `users` (login, password, role)
- `schema/002_add_settings.sql` — таблица `settings` (изменение схемы по п.7)

Схема синхронизирована с кодом (`server/authcheck.cpp`, `server/simpleserver.cpp`) и с миграциями Liquibase.

---

## 2. Анализ инструментов статического анализа SQL

Анализ выполнен по каталогу: **https://analysis-tools.dev/tag/sql**

**Выбор: SQLFluff**

- Поддержка диалекта **SQLite** (наша СУБД).
- Удобная интеграция в CI: установка через `pip install sqlfluff`, одна команда `sqlfluff lint`.
- Проверка стиля и части антипаттернов SQL, активная разработка и сообщество.

Альтернативы (SQLCheck и др.) рассмотрены; для SQLite и пайплайна без лишних зависимостей SQLFluff оказался наиболее удобным.

---

## 3. Шаг проверки безопасности SQL в CI/CD для всех веток

Добавлен шаг **SQL Security Check** (см. **`COPY_SQL_ANALYSIS_TO_TEAMCITY.txt`**):

- Запускается для всех веток.
- Устанавливает SQLFluff и выполняет `sqlfluff lint schema/ --dialect sqlite`.
- Конфигурация линтера: **`.sqlfluff`** (dialect = sqlite).

Скрипт шага можно вставить в TeamCity как Custom script в Command Line step.

---

## 4. Анализ инструментов миграции схемы БД в CI/CD

Рассмотрены варианты:

- **Liquibase** — открытая, СУБД-независимая библиотека; поддержка SQLite, XML/YAML/JSON/SQL; откат изменений, dry-run, единый changelog для разных окружений.
- **Flyway** — в основном SQL/Java; проще, но меньше возможностей и хуже поддержка нескольких СУБД из одного набора миграций.

**Выбор: Liquibase** — лучше подходит для проекта с возможной сменой окружений и необходимостью единого описания миграций (в т.ч. для SQLite в CI и при необходимости других СУБД).

В репозитории добавлены:

- **`liquibase.properties`** — драйвер, URL (по умолчанию `jdbc:sqlite:./campus_helper_ci.db`), путь к changelog.
- **`database/changelog/`** — мастер-файл `db.changelog-master.xml` и SQL-чанжсеты:
  - `001_initial.sql` — таблица `users` и начальные данные;
  - `002_add_settings.sql` — таблица `settings`.

---

## 5. Шаг(и) в пайплайне DEV: развертывание схемы на STAGE

Для DEV-ветки добавлен шаг **Liquibase Update** (см. **`COPY_LIQUIBASE_TO_TEAMCITY.txt`**):

- Устанавливаются Java и Liquibase CLI (при отсутствии).
- Выполняется `liquibase update` по `liquibase.properties` из корня репозитория.
- В CI целевая БД — файл `campus_helper_ci.db` в рабочей копии (аналог STAGE/тестовой БД).
- Сверка схем TEST/STAGE при необходимости выполняется через `liquibase diff` или вручную; в данном шаге накатывается единый changelog на целевую БД.

Шаг добавляется в Build Configuration, привязанную к ветке **dev**.

---

## 6. Отдельный пайплайн для PROD

Создаётся отдельная **Build Configuration** в TeamCity (например, «Deploy PROD»), по возможности идентичная пайплайну для DEV, но:

- Запускается по ветке **main** или по тегу/ручному запуску.
- В шаге Liquibase на агенте (или через параметры) в `liquibase.properties` задаётся URL PROD-БД, например:  
  `url=jdbc:sqlite:/path/to/prod/campus_helper.db`.  
  Либо на PROD-сервере выполняется развертывание по SSH по той же инструкции.

Подробности — в **`COPY_LIQUIBASE_TO_TEAMCITY.txt`**.

---

## 7. Внесённое изменение в базу данных (актуальная схема)

Добавлена миграция **002** — новая таблица **`settings`**:

- **`database/changelog/002_add_settings.sql`** — Liquibase changeset.
- **`schema/002_add_settings.sql`** — копия изменения в директории актуальной схемы.

После применения миграций схема БД содержит таблицы: `users`, `settings`.

---

## 8. Проверка работы шагов в пайплайне

- **SQL Security Check**: запустить сборку по любой ветке с директорией `schema/` и файлами `*.sql` — шаг должен проходить (при отсутствии нарушений правил SQLFluff).
- **Liquibase Update**: запустить сборку по ветке **dev** (или конфигурацию с Liquibase) — в рабочей директории агента должен появиться/обновиться файл `campus_helper_ci.db` с таблицами `users` и `settings`; при повторном запуске шаг должен завершаться без ошибок (changelog уже применён).

Схемы на всех окружениях, где выполняется один и тот же Liquibase changelog, остаются идентичными.

---

## Файлы, добавленные в ЛР8

| Путь | Назначение |
|------|-------------|
| `schema/001_initial.sql` | Актуальная схема: users |
| `schema/002_add_settings.sql` | Актуальная схема: settings |
| `.sqlfluff` | Конфиг SQLFluff (dialect sqlite) |
| `liquibase.properties` | Конфиг Liquibase (url, changelog) |
| `database/changelog/db.changelog-master.xml` | Мастер-чанжлог |
| `database/changelog/001_initial.sql` | Миграция: users |
| `database/changelog/002_add_settings.sql` | Миграция: settings |
| `COPY_SQL_ANALYSIS_TO_TEAMCITY.txt` | Шаг TeamCity: SQL Security Check |
| `COPY_LIQUIBASE_TO_TEAMCITY.txt` | Шаг TeamCity: Liquibase Update (DEV/PROD) |
