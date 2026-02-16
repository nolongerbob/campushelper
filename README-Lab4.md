# Лабораторная работа 4 — Пункт 1: загрузка образа в Docker Hub

## 1. Подключиться к Docker Hub

```bash
docker login
```

Введите имя пользователя Docker Hub и пароль (или Personal Access Token).

---

## 2. Вывести ID образов и контейнеров

**Список образов** (пригодятся REPOSITORY и TAG для push):

```bash
docker images
```

**Список контейнеров** (ID контейнеров):

```bash
docker ps -a
```

---

## 3. Собрать образ приложения (если ещё не собран)

Из каталога `Documents`:

```bash
cd ~/Documents
export DOCKERHUB_USER=ВАШ_ЛОГИН_НА_DOCKERHUB
sudo docker compose build server
```

Образ будет помечен как `ВАШ_ЛОГИН_НА_DOCKERHUB/campus-helper-server:latest`.

Либо без переменной — собрать и потом переименовать образ:

```bash
sudo docker compose build server
sudo docker tag documents-server:latest ВАШ_ЛОГИН_НА_DOCKERHUB/campus-helper-server:latest
```

(Если имя образа другое — смотрите вывод `docker images`; имя может быть `documents-server` или иное в зависимости от имени папки проекта.)

---

## 4. Загрузить образ в Docker Hub

Сначала создайте репозиторий на https://hub.docker.com (например, `campus-helper-server`). Затем:

```bash
sudo docker push ВАШ_ЛОГИН_НА_DOCKERHUB/campus-helper-server:latest
```

Подставьте свой логин вместо `ВАШ_ЛОГИН_НА_DOCKERHUB`.

---

## Краткая последовательность (подставьте YOUR_USERNAME)

```bash
docker login
export DOCKERHUB_USER=YOUR_USERNAME
cd ~/Documents
sudo docker compose build server
docker images
sudo docker push YOUR_USERNAME/campus-helper-server:latest
```

После успешного push образ появится в репозитории на Docker Hub.

---

# Пункт 2: Загрузить и развернуть jetbrains/teamcity-server

По [инструкции на Docker Hub](https://hub.docker.com/r/jetbrains/teamcity-server) нужны: образ с Hub, каталоги для данных и логов, порт 8111.

## Вариант А: через docker compose (удобнее)

Из каталога `Documents`:

```bash
cd ~/Documents
sudo docker compose -f docker-compose.teamcity.yml pull
sudo docker compose -f docker-compose.teamcity.yml up -d
```

Образ скачается, контейнер запустится с томами для данных и логов. Веб-интерфейс: **http://localhost:8111**.

Остановить:

```bash
sudo docker compose -f docker-compose.teamcity.yml down
```

## Вариант Б: только docker (как в инструкции образа)

**1. Загрузить образ с Docker Hub**

```bash
sudo docker pull jetbrains/teamcity-server
```

**2. Создать каталоги на хосте для данных и логов**

```bash
mkdir -p ~/teamcity-data ~/teamcity-logs
```

**3. Запустить контейнер**

```bash
sudo docker run -d --name teamcity-server-instance \
  -v /home/parallels/teamcity-data:/data/teamcity_server/datadir \
  -v /home/parallels/teamcity-logs:/opt/teamcity/logs \
  -p 8111:8111 \
  jetbrains/teamcity-server
```

(Путь замените на свой домашний каталог при необходимости.)

Веб-интерфейс: **http://localhost:8111**. При первом запуске TeamCity может инициализироваться несколько минут.
