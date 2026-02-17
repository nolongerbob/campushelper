# Лабораторная работа 5

## План

1. Добавить к шагам ЛР4 шаги **развёртывания на stage-сервере** (образ из Docker Hub + БД/compose).
2. Развернуть на **test-стенде** образ **jetbrains/teamcity-agent**, настроить для работы с TeamCity Server.
3. Внести изменение в репозиторий по **GitFlow** (или выбранной методологии).
4. Зафиксировать **успешную сборку** из кода в **feature-ветке** в TeamCity.
5. Создать **pull request** feature → **dev** с согласованием другим членом команды.
6. После согласования: зафиксировать **сборку из dev** и **развёртывание на stage** из созданного образа.

---

## 1. Развёртывание на stage-сервере

Используется образ приложения из Docker Hub и БД (volume), как в docker-compose из ЛР3.

### Файлы

- **docker-compose.stage.yml** — на stage-сервере поднимаются приложение (образ из Hub) и volume для БД.

### На stage-сервере

```bash
# Клонировать репо или скопировать docker-compose.stage.yml
export DOCKER_IMAGE=danprog19/campus-helper-server:latest   # или тег из сборки
docker compose -f docker-compose.stage.yml up -d
```

Образ можно переопределять после сборки в TeamCity, например:

```bash
export DOCKER_IMAGE=danprog19/campus-helper-server:build42
docker compose -f docker-compose.stage.yml up -d
```

### В TeamCity (дополнение к шагам ЛР4)

Добавить шаги:

1. **Сборка образа** (уже есть) — `docker build -t danprog19/campus-helper-server:%build.number% ./server`.
2. **Push в Docker Hub** — `docker push danprog19/campus-helper-server:%build.number%`.
3. **Развёртывание на stage** — по выбору:
   - **SSH**: подключение к stage-серверу и выполнение:
     ```bash
     export DOCKER_IMAGE=danprog19/campus-helper-server:%build.number%
     cd /path/to/repo && docker compose -f docker-compose.stage.yml pull && docker compose -f docker-compose.stage.yml up -d
     ```
   - или **скрипт/команда**, которая на stage делает `docker pull` и `docker compose -f docker-compose.stage.yml up -d`.

Состав и порядок шагов можно менять под ваш тип приложения.

### Конфликт имён контейнеров в шаге «Docker Compose»

Если сборка падает с **«The container name "/campus-helper-server" is already in use»**, на агенте уже есть контейнер с таким именем (прошлая сборка или ручной запуск).

**Что сделано в репозитории:** в `docker-compose.yml` (или `arch/docker-compose.yml`) у сервиса приложения убрано поле **container_name**. Тогда при каждом запуске Docker Compose создаёт контейнер с именем вида `<проект>_server_1`, и сборки не конфликтуют.

**В TeamCity — шаг «Docker Compose»:**

**Вариант 1:** В **Additional arguments** укажите уникальный проект: `-p build%build.number%`. Тогда каждая сборка получит свой набор контейнеров.

**Вариант 2:** Перед `up` выполните `down` для очистки старых контейнеров. В **Command** вместо просто `up -d` используйте:
```
down && up -d
```
Или в **Additional arguments**: `down && up -d` (если команда поддерживает `&&`).

**Вариант 3:** В **Command** перед `docker compose up` добавьте удаление старого контейнера:
```
docker rm -f campus-helper-server 2>/dev/null || true
docker compose up -d
```

---

## 2. TeamCity Agent на test-стенде — что это и как сделать

### Что это значит

- **TeamCity Server** — уже запущен (ЛР4). Он только принимает задачи и показывает интерфейс, сам сборки не выполняет.
- **TeamCity Agent** — программа, которая **выполняет сборки**: запускает шаги (команды, Docker и т.д.). Без агента сборки висят в очереди и не выполняются.
- **Test-стенд** — место, где запускается агент: та же машина, что и сервер, или отдельная ВМ/ПК.
- **«Настроить для работы с уже запущенным сервером»** = запустить агент с адресом этого сервера и в веб-интерфейсе TeamCity **авторизовать** агента (разрешить ему выполнять сборки).

### Шаги

**1. Запустить агент (образ jetbrains/teamcity-agent)**

Агент должен достучаться до сервера по **IP хоста**, не по `localhost` (внутри контейнера localhost — это сам контейнер).

Если сервер и агент на **одной машине** (например, IP сервера 10.211.55.5):

```bash
cd ~/Documents
export TEAMCITY_SERVER_URL=http://10.211.55.5:8111
docker compose -f docker-compose.teamcity-agent.yml up -d
```

Если агент на **другой машине** — подставьте IP той машины, где запущен TeamCity Server.

**Вариант одной командой:**

```bash
docker run -d --name teamcity-agent \
  -e SERVER_URL=http://10.211.55.5:8111 \
  -v teamcity-agent-conf:/data/teamcity_agent/conf \
  jetbrains/teamcity-agent
```

**2. Авторизовать агента в TeamCity**

- Откройте TeamCity: **http://10.211.55.5:8111** (или ваш адрес сервера).
- Вверху: **Agents** (или Агенты).
- Появится агент в статусе **Unauthorized**.
- Нажмите на него → **Authorize** (Авторизовать).

После этого агент начнёт брать сборки из очереди и выполнять их на test-стенде.

---

## 3. GitFlow и изменение в репозитории

- Ветки: **main** (или **master**), **dev**, **feature/название**.
- Изменения по функционалу делаются в **feature-ветке**, затем PR в **dev**.

Пример:

```bash
git checkout dev
git pull
git checkout -b feature/новая-функция
# правки в коде
git add .
git commit -m "Описание изменения"
git push -u origin feature/новая-функция
```

Дальше — Pull Request **feature/новая-функция** → **dev**, ревью и согласование другим участником, затем merge.

---

## 4. Сборка из feature-ветки в TeamCity

- В TeamCity в конфигурации сборки указать **VCS branch**: ветка `feature/...` (или branch specification).
- Запустить сборку вручную из этой ветки.
- Зафиксировать успешную сборку (скрин/отчёт).

---

## 5. Pull Request в dev

- На GitHub/GitLab: создать **Pull Request** из ветки **feature/...** в **dev**.
- Указать ревьюера (другой член команды).
- После одобрения — выполнить merge.

---

## 6. Сборка из dev и развёртывание на stage

- В TeamCity переключить сборку на ветку **dev** (или запустить сборку по коммиту в **dev**).
- Запустить сборку → образ пушится в Docker Hub.
- На **stage-сервере** выполнить (с нужным тегом образа):

  ```bash
  export DOCKER_IMAGE=danprog19/campus-helper-server:latest
  docker compose -f docker-compose.stage.yml pull
  docker compose -f docker-compose.stage.yml up -d
  ```

- На **test** (клиент) поменять IP на адрес stage-сервера и проверить работу приложения.
- Продемонстрировать изменения в коде (коммиты в dev, работа приложения на stage).

---

## Файлы в репозитории

| Файл | Назначение |
|------|------------|
| `docker-compose.stage.yml` | Развёртывание приложения + БД на stage из образа Hub |
| `docker-compose.teamcity-agent.yml` | Запуск TeamCity Agent на test-стенде |

При необходимости шаги в TeamCity (Dockerfile, stage-образ, деплой) можно донастроить под ваш репозиторий и окружение.
