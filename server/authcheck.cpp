#include "authcheck.h"
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QVariant>

static const char s_conn[] = "campus_helper_test_conn";

bool initTestDatabase(const QString &dbPath)
{
    if (QSqlDatabase::contains(QLatin1String(s_conn)))
        QSqlDatabase::removeDatabase(QLatin1String(s_conn));

    QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), QLatin1String(s_conn));
    db.setDatabaseName(dbPath);
    if (!db.open())
        return false;

    QSqlQuery q(db);
    if (!q.exec(QLatin1String(
        "CREATE TABLE IF NOT EXISTS users ("
        " login TEXT PRIMARY KEY,"
        " password TEXT NOT NULL,"
        " role TEXT NOT NULL)")))
        return false;

    if (!q.exec(QLatin1String(
        "INSERT OR IGNORE INTO users(login,password,role) VALUES"
        " ('student','student','student'),"
        " ('teacher','teacher','teacher')")))
        return false;

    return true;
}

QString checkAuth(const QString &dbPath, const QString &login, const QString &password)
{
    if (dbPath.isEmpty() || login.isEmpty())
        return QStringLiteral("authorization error ");

    if (!QSqlDatabase::contains(QLatin1String(s_conn))) {
        QSqlDatabase db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), QLatin1String(s_conn));
        db.setDatabaseName(dbPath);
        if (!db.open())
            return QStringLiteral("authorization error ");
    }

    QSqlDatabase db = QSqlDatabase::database(QLatin1String(s_conn));
    if (!db.isOpen())
        return QStringLiteral("authorization error ");

    QSqlQuery auth(db);
    auth.prepare(QStringLiteral("SELECT role FROM users WHERE login=? AND password=?"));
    auth.addBindValue(QVariant(login));
    auth.addBindValue(QVariant(password));

    if (auth.exec() && auth.next())
        return QStringLiteral("authorization yes ");
    return QStringLiteral("authorization error ");
}
