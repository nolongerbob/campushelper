// Лабораторная работа 7 — юнит-тесты авторизации и БД
#include <QtTest>
#include <QDir>
#include <QFile>
#include <QCoreApplication>
#include <QSqlDatabase>
#include "authcheck.h"

class TestAuth : public QObject
{
    Q_OBJECT
public:
    TestAuth() = default;

private slots:
    void initTestCase();
    void cleanupTestCase();

    void testDatabaseOpen();
    void testAuthStudent();
    void testAuthTeacher();
    void testAuthWrongCredentials();
    void testAuthEmptyLogin();
};

static QString s_dbPath;

void TestAuth::initTestCase()
{
    s_dbPath = QDir::temp().filePath(QStringLiteral("campus_helper_test_%1.db").arg(QCoreApplication::applicationPid()));
    QVERIFY2(initTestDatabase(s_dbPath), "initTestDatabase failed");
}

void TestAuth::cleanupTestCase()
{
    if (QFile::exists(s_dbPath))
        QFile::remove(s_dbPath);
    if (QSqlDatabase::contains("campus_helper_test_conn"))
        QSqlDatabase::removeDatabase("campus_helper_test_conn");
}

void TestAuth::testDatabaseOpen()
{
    QVERIFY2(QFile::exists(s_dbPath), "Test database file should exist");
    QString r = checkAuth(s_dbPath, QStringLiteral("student"), QStringLiteral("student"));
    QVERIFY2(r == QStringLiteral("authorization yes "), "DB should be open and auth should succeed");
}

void TestAuth::testAuthStudent()
{
    QString result = checkAuth(s_dbPath, QStringLiteral("student"), QStringLiteral("student"));
    QCOMPARE(result, QStringLiteral("authorization yes "));
}

void TestAuth::testAuthTeacher()
{
    QString result = checkAuth(s_dbPath, QStringLiteral("teacher"), QStringLiteral("teacher"));
    QCOMPARE(result, QStringLiteral("authorization yes "));
}

void TestAuth::testAuthWrongCredentials()
{
    QString result = checkAuth(s_dbPath, QStringLiteral("wronguser"), QStringLiteral("wrongpass"));
    QCOMPARE(result, QStringLiteral("authorization error "));
}

void TestAuth::testAuthEmptyLogin()
{
    QString result = checkAuth(s_dbPath, QString(), QStringLiteral("any"));
    QCOMPARE(result, QStringLiteral("authorization error "));
}

QTEST_APPLESS_MAIN(TestAuth)
#include "tst_auth.moc"
