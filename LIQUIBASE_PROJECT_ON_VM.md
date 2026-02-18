# Создание Liquibase-проекта и настройка liquibase.properties на ВМ (ЛР8)

В ЛР8 нужно на каждой ВМ (Test, Stage, Prod) создать **liquibase-проект** и отредактировать **liquibase.properties** под подключение к БД этой ВМ.

---

## Что такое «liquibase-проект» на ВМ

Это каталог на сервере, в котором лежат:

- **liquibase.properties** — настройки подключения к БД (url, username, password, changeLogFile)
- **database/changelog/** — файлы миграций (можно скопировать из репозитория или клонировать весь репозиторий)

Команды Liquibase (`liquibase update`, `liquibase status`) запускают из этого каталога.

---

## Пошагово: как сделать на каждой ВМ

### 1. Подключись к ВМ (Test, затем Stage, затем Prod)

```bash
ssh user@test-server    # или stage-server, prod-server
```

### 2. Установи Java и Liquibase на ВМ

```bash
# Java (пример для Ubuntu/Debian)
sudo apt-get update
sudo apt-get install -y openjdk-17-jre-headless

# Liquibase — в каталог /opt/liquibase (или в домашний каталог)
sudo mkdir -p /opt/liquibase
cd /tmp
wget https://github.com/liquibase/liquibase/releases/download/v4.24.0/liquibase-4.24.0.tar.gz
sudo tar -xzf liquibase-4.24.0.tar.gz -C /opt/liquibase
echo 'export PATH="/opt/liquibase:$PATH"' >> ~/.bashrc
source ~/.bashrc
liquibase --version
```

Если используешь **PostgreSQL**, установи драйвер и укажи его в classpath при необходимости:

```bash
# Пример: драйвер в /opt/liquibase/lib или через переменную LIQUIBASE_HOME
```

### 3. Создай каталог liquibase-проекта на ВМ

Вариант **А**: клонировать репозиторий (тогда уже есть `liquibase.properties` и `database/changelog/`):

```bash
cd /opt   # или домашний каталог
sudo git clone https://github.com/ВАШ_ЛОГИН/campushelper.git campus_helper_liquibase
cd campus_helper_liquibase
```

Вариант **Б**: создать каталог вручную и скопировать только нужное:

```bash
mkdir -p /opt/campus_helper_liquibase/database/changelog
cd /opt/campus_helper_liquibase
# Скопируй с своей машины: liquibase.properties, database/changelog/*.xml, database/changelog/*.sql
```

### 4. Отредактируй liquibase.properties на этой ВМ

Файл должен указывать на **БД именно этой ВМ** (Test — на тестовую БД, Stage — на stage, Prod — на prod).

**На ВМ Test:**

```bash
nano /opt/campus_helper_liquibase/liquibase.properties
```

Содержимое (подставь хост/порт/базу/логин/пароль):

```properties
changeLogFile=database/changelog/db.changelog-master.xml
url=jdbc:postgresql://localhost:5432/campus_helper
driver=org.postgresql.Driver
username=dbuser
password=secret
```

**На ВМ Stage** — то же самое, но `url` (и при необходимости логин/пароль) для Stage-БД:

```properties
changeLogFile=database/changelog/db.changelog-master.xml
url=jdbc:postgresql://localhost:5432/campus_helper
driver=org.postgresql.Driver
username=dbuser
password=secret
```

**На ВМ Prod** — то же, но для Prod-БД:

```properties
changeLogFile=database/changelog/db.changelog-master.xml
url=jdbc:postgresql://localhost:5432/campus_helper
driver=org.postgresql.Driver
username=dbuser
password=secret
```

Или если БД на том же хосте: `url=jdbc:postgresql://localhost:5432/campus_helper`. Если на другом хосте — подставь его вместо `localhost`.

### 5. Проверка на ВМ

Из каталога проекта на ВМ:

```bash
cd /opt/campus_helper_liquibase   # или путь, где лежит liquibase.properties
liquibase status
liquibase update
```

После этого схема БД на этой ВМ будет приведена в соответствие с чейнджлогом.

---

## Кратко по шагам ЛР8

| Шаг | Действие |
|-----|----------|
| 1 | На ВМ Test: установить Java + Liquibase, создать каталог проекта, скопировать changelog, отредактировать **liquibase.properties** (url/username/password для Test-БД). |
| 2 | На ВМ Stage: то же, **liquibase.properties** — с подключением к Stage-БД. |
| 3 | На ВМ Prod: то же, **liquibase.properties** — с подключением к Prod-БД. |

В CI/CD (TeamCity) шаг «Liquibase update» обычно запускается на агенте: либо агент уже на нужной ВМ, либо по SSH заходит на ВМ и там выполняет `cd проект && liquibase update`. В последнем случае на каждой ВМ должен быть свой каталог проекта и свой **liquibase.properties** с правильным url для этой ВМ.
