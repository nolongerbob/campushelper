# Лабораторная работа 6 — Статический анализ кода

## План

1. Исследовать доступные статические анализаторы для Qt/C++.
2. Выбрать минимум два анализатора:
   - анализатор качества кода
   - анализатор безопасности кода
   - средство поиска секретов
3. Добавить шаги статического анализа в TeamCity с проверкой критичности.

---

## 1. Исследование статических анализаторов для Qt/C++

### Анализаторы качества кода (C++)

- **cppcheck** — бесплатный анализатор качества кода для C/C++
- **Clang Static Analyzer** — встроен в Clang, проверяет типичные ошибки
- **Clang-Tidy** — проверка стиля и качества кода

### Анализаторы безопасности (C++)

- **PVS-Studio** — коммерческий, выявляет ошибки и уязвимости (CWE, CERT, MISRA)
- **Cppcheck** (с опцией `--enable=warning`) — базовые проверки безопасности
- **Clang Static Analyzer** — выявляет потенциальные уязвимости

### Поиск секретов

- **Trufflehog** — универсальный поиск секретов в коде и истории Git
- **git-secrets** — проверка коммитов на секреты
- **detect-secrets** — поиск секретов в файлах

---

## 2. Выбранные анализаторы

Для проекта **Campus Helper (Qt/C++)** выбраны:

1. **cppcheck** — анализатор качества кода (бесплатный, открытый исходный код)
2. **PVS-Studio Free** — анализатор безопасности (бесплатная версия без регистрации, работает с комментариями в коде)
3. **Trufflehog** — поиск секретов в репозитории (бесплатный, открытый исходный код)

**Примечание:** PVS-Studio Free работает без регистрации и лицензионного ключа, если в начале каждого исходного файла есть комментарий:
```cpp
// This is a personal academic project. Dear PVS-Studio, please check it.
// PVS-Studio Static Code Analyzer for C, C++, C#, and Java: https://pvs-studio.com
```
Этот комментарий уже добавлен во все файлы сервера.

---

## 3. Шаги статического анализа в TeamCity

### Шаг 1: Статический анализ cppcheck (качество кода)

**Runner type:** Command Line  
**Custom script:** выполнить `bash scripts/static-analysis/cppcheck.sh`

Или вставить содержимое скрипта напрямую в TeamCity.

**Критичность:** при обнаружении **BLOCKER** → билд завершается с ошибкой.

**Artifacts:** `server/cppcheck-report/** => static-analysis/cppcheck/`

---

### Шаг 2: Статический анализ PVS-Studio (безопасность)

**Runner type:** Command Line  
**Custom script:** выполнить `bash scripts/static-analysis/pvs-studio.sh`

**Важно:** перед использованием замените лицензию PVS-Studio в скрипте:
```bash
pvs-studio-analyzer credentials YOUR_EMAIL YOUR_LICENSE_KEY
```

**Критичность:** при обнаружении **CRITICAL** (err в отчете) → билд завершается с ошибкой.

**Artifacts:** `server/report/** => static-analysis/pvs-studio/`

---

### Шаг 3: Поиск секретов Trufflehog

**Runner type:** Command Line  
**Custom script:** выполнить `bash scripts/static-analysis/trufflehog.sh`

**Критичность:** при обнаружении **любого секрета** → билд завершается с ошибкой.

**Artifacts:** `trufflehog-report/** => static-analysis/trufflehog/`

---

## Порядок шагов в TeamCity

1. **VCS Checkout** (автоматически)
2. **Docker** — сборка образа
3. **Docker Compose** — запуск контейнеров
4. **Static Analysis: cppcheck** — анализ качества кода
5. **Static Analysis: PVS-Studio** — анализ безопасности
6. **Static Analysis: Trufflehog** — поиск секретов
7. **Command Line** (остальные шаги)

---

## Настройка артефактов

В настройках сборки → **Artifacts** добавьте:

```
server/cppcheck-report/** => static-analysis/cppcheck/
server/report/** => static-analysis/pvs-studio/
trufflehog-report/** => static-analysis/trufflehog/
```

---

## Настройка Report Tabs

В настройках проекта → **Report Tabs** → **Create new build report tab**:

**Для PVS-Studio:**
- **Name:** PVS-Studio Report
- **Start page:** `static-analysis/pvs-studio/index.html`

**Для cppcheck:**
- **Name:** cppcheck Report  
- **Start page:** `static-analysis/cppcheck/index.html`

---

## Критичность и завершение билда с ошибкой

- **cppcheck:** при обнаружении **BLOCKER** → `exit 1`
- **PVS-Studio:** при обнаружении **CRITICAL** (err в отчете) → `exit 1`
- **Trufflehog:** при обнаружении **любого секрета** → `exit 1`

---

## Файлы скриптов

Скрипты сохранены в `scripts/static-analysis/`:
- `cppcheck.sh` — анализ качества кода
- `pvs-studio.sh` — анализ безопасности
- `trufflehog.sh` — поиск секретов

Используйте их в шагах TeamCity или скопируйте содержимое в Custom script.
