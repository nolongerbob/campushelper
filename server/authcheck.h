#ifndef AUTHCHECK_H
#define AUTHCHECK_H

#include <QString>

// Тестируемые функции для ЛР7 (юнит-тесты).
// Проверка авторизации по логину/паролю против БД (таблица users).

// Возвращает "authorization yes " при успехе, "authorization error " при ошибке.
QString checkAuth(const QString &dbPath, const QString &login, const QString &password);

// Открывает БД по пути, создаёт таблицу users при необходимости, вставляет тестовых пользователей.
// Возвращает true при успехе.
bool initTestDatabase(const QString &dbPath);

#endif // AUTHCHECK_H
