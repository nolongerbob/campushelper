# Лабораторная работа 3 — Campus Helper (часть 2)

СУБД: **SQLite3**. Сервер и утилиты в Docker; клиент запускается локально (Qt GUI).

---

## Только Docker (без docker-compose)

### 1. Получить образ SQLite3 с Docker Hub

```bash
docker pull keinos/sqlite3
```

### 2. Вывести версию sqlite3 из контейнера

```bash
docker run --rm keinos/sqlite3 --version
```

### 3. Вывести данные из таблицы authorization через контейнер

Сначала нужно, чтобы БД существовала. Вариант **А** — сервер уже запускали в Docker (например через compose), тогда используйте тот же volume. Вариант **Б** — с нуля только через `docker`:

**Б.1.** Создать volume и запустить сервер один раз (создаст БД и таблицу):

```bash
docker volume create campus-db
docker build -t campus-server ./server
docker run --rm -v campus-db:/app/data -e DB_PATH=/app/data/campus_helper.db campus-server
```

Подождать несколько секунд (в логах появится «server is started»), затем остановить: `Ctrl+C`.

**Б.2.** Вывести данные из таблицы authorization (в образе первым аргументом должна идти команда `sqlite3`):

```bash
docker run --rm -v campus-db:/data keinos/sqlite3 sqlite3 /data/campus_helper.db "SELECT * FROM authorization;"
```

**Добавить пользователя в БД через терминал** (нужен `--user root`, иначе БД только для чтения):

```bash
docker run --rm --user root -v campus-db:/data keinos/sqlite3 sqlite3 /data/campus_helper.db "INSERT INTO authorization(login,password,role) VALUES ('steve', 'steve', 'student');"
```

При использовании **docker compose** (том `db-data`) — без второго слова `sqlite3`, только путь к БД и SQL:

```bash
docker compose run --rm --user root sqlite3 /data/campus_helper.db "INSERT INTO authorization(login,password,role) VALUES ('steve', 'steve', 'student');"
```

Ожидаемый вывод:

```
student|student|student
teacher|teacher|teacher
```

---

## С использованием docker-compose

## 1. Образ SQLite3 с Docker Hub

```bash
docker compose pull sqlite3
# или при первом run образ скачается автоматически (keinos/sqlite3)
```

## 2. Запуск сервера в Docker

```bash
docker compose up -d server
```

Сервер создаёт БД в volume `db-data` по пути `/app/data/campus_helper.db` и таблицу **authorization** (login, password, role).

## 3. Версия sqlite3 из контейнера

```bash
docker compose run --rm sqlite3 --version
```

Или скрипт:

```bash
./scripts/sqlite-version.sh
```

## 4. Данные из таблицы authorization через контейнер

Сначала убедитесь, что сервер хотя бы раз был запущен (чтобы создалась БД):

```bash
docker compose up -d server
# подождать пару секунд
docker compose run --rm sqlite3 /data/campus_helper.db "SELECT * FROM authorization;"
```

Или скрипт:

```bash
./scripts/show-authorization-table.sh
```

Ожидаемый вывод (пример):

```
student|student|student
teacher|teacher|teacher
```

## 5. Клиент

Клиент — Qt-приложение, подключается к серверу по `127.0.0.1:45454`. Запускайте клиент локально (сборка через Qt/qmake в папке `client/`). Для входа: **student** / **student** или **teacher** / **teacher**.

## 6. Логи сервера

Логи с временными метками (запуск, попытки авторизации, отключения):

```bash
docker compose logs -f server
```

## Структура

- **server/** — сервер (Qt, QSQLITE), таблица `authorization`, логи с датой/временем.
- **client/** — клиент (логин, расписание).
- **docker-compose.yml** — сервисы `server` и `sqlite3` (образ с Docker Hub), общий volume `db-data`.
- **scripts/** — скрипты для вывода версии sqlite3 и данных таблицы authorization.
