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

1. **cppcheck** — анализатор качества кода ✅ (категория a)
2. **Clang Static Analyzer** — анализатор безопасности кода ✅ (категория b)
3. **Trufflehog** — поиск секретов в репозитории ✅ (категория c)

### Описание анализаторов:

#### cppcheck (качество кода)
- **Тип:** Анализатор качества кода для C/C++
- **Лицензия:** GPL, бесплатный
- **Поддержка ARM64:** ✅ Да
- **Что проверяет:** Утечки памяти, неиспользуемые переменные, логические ошибки, стиль кода

#### Clang Static Analyzer (безопасность)
- **Тип:** Анализатор безопасности кода для C/C++
- **Лицензия:** Apache 2.0, бесплатный
- **Поддержка ARM64:** ✅ Да (встроен в Clang)
- **Что проверяет:** Buffer overflow, use-after-free, null pointer dereference, memory leaks, race conditions

#### Trufflehog (поиск секретов)
- **Тип:** Средство поиска учетных данных/секретов
- **Лицензия:** Apache 2.0, бесплатный
- **Поддержка ARM64:** ✅ Да
- **Что проверяет:** API ключи, пароли, токены, приватные ключи в коде и Git истории

### ⚠️ Альтернатива: PVS-Studio

**PVS-Studio не поддерживает ARM64 на Linux** (только x86_64). Поэтому выбран **Clang Static Analyzer** как альтернатива - он:
- ✅ Работает на ARM64 нативно
- ✅ Бесплатный и открытый исходный код
- ✅ Встроен в Clang (не требует установки)
- ✅ Находит проблемы безопасности (CWE, CERT)

---

## 3. Шаги статического анализа в TeamCity

**Готовые скрипты:** см. файл `TEAMCITY_STATIC_ANALYSIS_FINAL.txt` — там готовый код для копирования.

### Шаг 1: Статический анализ cppcheck (качество кода) — ОБЯЗАТЕЛЬНО

**Runner type:** Command Line  
**Step name:** Static Analysis: cppcheck  
**Run:** Custom script  
**Working directory:** ПУСТО

**Custom script:** скопируй из `TEAMCITY_STATIC_ANALYSIS_FINAL.txt` (раздел "ШАГ 1: CPPCHECK")

**Критичность:** при обнаружении **BLOCKER** → билд завершается с ошибкой.

**Artifacts:** `server/cppcheck-report/** => static-analysis/cppcheck/`

---

### Шаг 2: Статический анализ Clang Static Analyzer (безопасность) — ОБЯЗАТЕЛЬНО

**Runner type:** Command Line  
**Step name:** Static Analysis: Clang Static Analyzer (security)  
**Run:** Custom script  
**Working directory:** ПУСТО

**Custom script:** скопируй из `COPY_CLANG_TO_TEAMCITY.txt`

**Критичность:** предупреждения о проблемах безопасности → билд продолжается, но проблемы отображаются в отчете.

**Artifacts:** `server/report-clang/** => clang-analyzer-report/`

**Report Tab:** `clang-analyzer-report/index.html`

---

### Шаг 3: Поиск секретов Trufflehog — ОБЯЗАТЕЛЬНО

**Runner type:** Command Line  
**Step name:** Static Analysis: Trufflehog  
**Run:** Custom script  
**Working directory:** ПУСТО

**Custom script:** скопируй из `TEAMCITY_STATIC_ANALYSIS_FINAL.txt` (раздел "ШАГ 2: TRUFFLEHOG")

**Критичность:** при обнаружении **любого секрета** → билд завершается с ошибкой.

**Artifacts:** `trufflehog-report/** => static-analysis/trufflehog/`

---

### Шаг 4: Статический анализ PVS-Studio (опционально, только для x86_64)

PVS-Studio может не работать на ARM64 или если сайт недоступен. Шаг пропускается автоматически, если установка не удалась.

**Примечание:** Для ARM64 используйте **Clang Static Analyzer** (Шаг 2) вместо PVS-Studio.

**Runner type:** Command Line  
**Custom script:** скопируй из `scripts/static-analysis/pvs-studio.sh` или используй готовый код из `COPY_TO_TEAMCITY.txt`

**Критичность:** при обнаружении **CRITICAL** (err в отчете) → билд завершается с ошибкой.

**Artifacts:** `server/report/** => static-analysis/pvs-studio/`

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
