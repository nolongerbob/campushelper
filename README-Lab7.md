# Лабораторная работа 7 — Тестирование ПО

## План выполнения

1. Выбрать библиотеку/фреймворк для тестирования на выбранном стеке.
2. Разработать набор юнит- и интеграционных тестов (покрытие ≥40% функционала).
3. Добавить в конфигурации сборки в TeamCity шаги автоматического тестирования (для любой ветки).
4. Продемонстрировать: одно неуспешное прохождение теста (плохой код) и по одному успешному для feature/dev/prod.

---

## 1. Выбранный инструмент

**QTestLib** (Qt Test) — библиотека для тестирования приложений Qt (C++). Подходит для юнит-тестов логики авторизации и работы с БД без GUI.

- Подключение: `QT += testlib` в `.pro`
- Запуск: `./campus_helper_tests`

---

## 2. Набор тестов

Проект тестов: `tests/campus_helper_tests.pro`, тестируемый модуль: `server/authcheck.cpp` (открытие БД, запросы, проверка логина/пароля).

| № | Тест | Модуль | Что проверяет | Данные | Ожидаемый результат |
|---|------|--------|----------------|--------|----------------------|
| 1 | testDatabaseOpen | authcheck, БД | Открытие БД и наличие файла | Временная БД в /tmp | Файл создан, запрос к БД успешен |
| 2 | testAuthStudent | authcheck | Авторизация учётной записи student | login=student, password=student | "authorization yes " |
| 3 | testAuthTeacher | authcheck | Авторизация учётной записи teacher | login=teacher, password=teacher | "authorization yes " |
| 4 | testAuthWrongCredentials | authcheck | Отказ при неверных данных | login=wronguser, password=wrongpass | "authorization error " |
| 5 | testAuthEmptyLogin | authcheck | Отказ при пустом логине | login=пусто | "authorization error " |

Покрытие: открытие БД, запросы к таблице `users`, авторизация (успех/ошибка) — соответствует требованию по покрытию функционала.

### Пример кода теста (testAuthStudent)

```cpp
void TestAuth::testAuthStudent()
{
    QString result = checkAuth(s_dbPath, QStringLiteral("student"), QStringLiteral("student"));
    QCOMPARE(result, QStringLiteral("authorization yes "));
}
```

---

## 3. Шаг в TeamCity

- **Runner type:** Command Line  
- **Step name:** Unit Tests  
- **Run:** Custom script  
- **Working directory:** пусто (корень репозитория)

Готовый скрипт для вставки в поле «Custom script» — в файле **`COPY_UNIT_TESTS_TO_TEAMCITY.txt`**.

Кратко шаг делает:
- установка qt5-qmake, qtbase5-dev, build-essential, libqt5sql5-sqlite;
- `cd tests`, `qmake`, `make`;
- запуск `./campus_helper_tests`;
- выход с кодом 0 только при успехе всех тестов.

Рекомендуется поставить шаг **после** статического анализа (например, после cppcheck).

---

## 4. Демонстрация прохождения тестов

- **Успешное прохождение:** сборка из веток main, dev, feature — все 5 тестов зелёные (5/5).
- **Неуспешное прохождение:** временно изменить код (например, в `authcheck.cpp` всегда возвращать `"authorization error "`) или ожидание в тесте неверную строку — один или несколько тестов падают; после исправления кода сборка снова 5/5.

---

## Запуск тестов локально

```bash
cd tests
qmake campus_helper_tests.pro
make
./campus_helper_tests
```

Вывод при успехе: `Totals: 7 passed, 0 failed`.
