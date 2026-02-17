// This is a personal academic project. Dear PVS-Studio, please check it.
// PVS-Studio Static Code Analyzer for C, C++, C#, and Java: https://pvs-studio.com
#include "simpleserver.h"

#include <QTextStream>
#include <QSqlQuery>
#include <QSqlError>
#include <QDateTime>

static void log(const QString &msg)
{
    QTextStream(stdout) << QDateTime::currentDateTime().toString(Qt::ISODate)
                        << " [SERVER] " << msg << Qt::endl;
}

SimpleServer::SimpleServer(QObject *parent)
    : QTcpServer(parent)
{
    initDatabase();
}

void SimpleServer::initDatabase()
{
    if (!QSqlDatabase::contains(QStringLiteral("campus_helper_conn"))) {
        m_db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"),
                                         QStringLiteral("campus_helper_conn"));
    } else {
        m_db = QSqlDatabase::database(QStringLiteral("campus_helper_conn"));
    }

    const QString dbPath = qEnvironmentVariableIsSet("DB_PATH")
        ? qEnvironmentVariable("DB_PATH")
        : QStringLiteral("campus_helper.db");
    m_db.setDatabaseName(dbPath);
    if (!m_db.open()) {
        QTextStream(stderr) << "db open error: " << m_db.lastError().text() << Qt::endl;
        return;
    }
    log(QStringLiteral("db is open: ") + dbPath);

    QSqlQuery q(m_db);
    if (!q.exec(QStringLiteral(
                    "CREATE TABLE IF NOT EXISTS authorization ("
                    " login TEXT PRIMARY KEY,"
                    " password TEXT NOT NULL,"
                    " role TEXT NOT NULL)"))) {
        QTextStream(stderr) << "db create table error: " << q.lastError().text() << Qt::endl;
    }

    if (!q.exec(QStringLiteral(
                    "INSERT OR IGNORE INTO authorization(login,password,role) VALUES"
                    " ('student','student','student'),"
                    " ('teacher','teacher','teacher')"))) {
        QTextStream(stderr) << "db insert error: " << q.lastError().text() << Qt::endl;
    }
}

void SimpleServer::incomingConnection(qintptr socketDescriptor)
{
    auto *socket = new QTcpSocket(this);
    socket->setSocketDescriptor(socketDescriptor);

    m_clients << socket;

    connect(socket, &QTcpSocket::readyRead,
            this, &SimpleServer::onReadyRead);
    connect(socket, &QTcpSocket::disconnected,
            this, &SimpleServer::onDisconnected);
}

void SimpleServer::onReadyRead()
{
    auto *socket = qobject_cast<QTcpSocket*>(sender());
    if (!socket)
        return;

    m_readBuffers[socket] += socket->readAll();
    QByteArray &buf = m_readBuffers[socket];

    int pos;
    while ((pos = buf.indexOf('\n')) >= 0) {
        QByteArray line = buf.left(pos).trimmed();
        buf = buf.mid(pos + 1);

        if (line.isEmpty())
            continue;

        // AUTH login password
        if (line.startsWith("AUTH ")) {
            QList<QByteArray> parts = line.mid(5).split(' ');
            const QByteArray login = parts.value(0);
            const QByteArray pass = parts.value(1);

            log(QStringLiteral("auth attempt: login=\"") + QString::fromUtf8(login)
                + QStringLiteral("\" (db open: ") + (m_db.isOpen() ? QStringLiteral("yes") : QStringLiteral("no")) + QLatin1Char(')'));

            if (parts.size() >= 2 && m_db.isOpen()) {
                QSqlQuery auth(m_db);
                auth.prepare(QStringLiteral(
                                 "SELECT role FROM authorization "
                                 "WHERE login=? AND password=?"));
                auth.addBindValue(QString::fromUtf8(login));
                auth.addBindValue(QString::fromUtf8(pass));

                if (auth.exec() && auth.next()) {
                    const QString role = auth.value(0).toString();
                    m_usernames[socket] = QString::fromUtf8(login);
                    socket->write("OK ");
                    socket->write(role.toUtf8());
                    socket->write("\n");
                    socket->flush();
                    log(QStringLiteral("authorization yes: \"") + QString::fromUtf8(login) + QLatin1Char('"'));
                } else {
                    socket->write("FAIL\n");
                    socket->flush();
                    log(QStringLiteral("authorization error: \"") + QString::fromUtf8(login) + QLatin1Char('"'));
                }
            } else {
                socket->write("FAIL\n");
                socket->flush();
                log(QStringLiteral("authorization error (bad request or db): \"") + QString::fromUtf8(login) + QLatin1Char('"'));
            }
            continue;
        }

        if (line.startsWith("LOGIN ")) {
            const QString user = QString::fromUtf8(line.mid(6));
            m_usernames[socket] = user;
            continue;
        }

        // ADDUSER login password role — добавление пользователя в БД (только для teacher)
        if (line.startsWith("ADDUSER ")) {
            QList<QByteArray> parts = line.mid(8).split(' ');
            const QString caller = m_usernames.value(socket);
            if (caller != QStringLiteral("teacher")) {
                socket->write("ADDUSER_FAIL Только преподаватель может добавлять пользователей\n");
                socket->flush();
                continue;
            }
            if (parts.size() < 3 || !m_db.isOpen()) {
                socket->write("ADDUSER_FAIL Неверный формат или БД недоступна\n");
                socket->flush();
                continue;
            }
            const QString login = QString::fromUtf8(parts.value(0)).trimmed();
            const QString password = QString::fromUtf8(parts.value(1));
            const QString role = QString::fromUtf8(parts.value(2)).trimmed().toLower();
            if (login.isEmpty() || password.isEmpty() || (role != QStringLiteral("student") && role != QStringLiteral("teacher"))) {
                socket->write("ADDUSER_FAIL Логин, пароль и роль (student/teacher) обязательны\n");
                socket->flush();
                continue;
            }
            QSqlQuery ins(m_db);
            ins.prepare(QStringLiteral(
                "INSERT INTO authorization(login,password,role) VALUES(?,?,?)"));
            ins.addBindValue(login);
            ins.addBindValue(password);
            ins.addBindValue(role);
            if (ins.exec()) {
                socket->write("ADDUSER_OK\n");
                socket->flush();
                log(QStringLiteral("user added: \"") + login + QStringLiteral("\" role=") + role);
            } else {
                QString err = ins.lastError().text();
                if (err.contains(QStringLiteral("UNIQUE"), Qt::CaseInsensitive))
                    socket->write("ADDUSER_FAIL Пользователь с таким логином уже существует\n");
                else
                    socket->write("ADDUSER_FAIL " + err.toUtf8() + "\n");
                socket->flush();
            }
            continue;
        }

        if (line == "SCHEDULE") {
            socket->write("10.02.2026;Математика;А-101\n"
                          "11.02.2026;Программирование;Б-202\n"
                          "12.02.2026;Базы данных;В-103\n");
            socket->flush();
        } else if (line == "NEWS") {
            socket->write("Новость 1: День открытых дверей\n"
                          "Новость 2: Зачёт по программированию\n");
            socket->flush();
        }
    }
}

void SimpleServer::onDisconnected()
{
    auto *socket = qobject_cast<QTcpSocket*>(sender());
    if (!socket)
        return;

    QString user = m_usernames.value(socket, QStringLiteral("(unknown)"));
    qintptr desc = socket->socketDescriptor();
    m_clients.removeAll(socket);
    m_usernames.remove(socket);
    m_readBuffers.remove(socket);
    socket->deleteLater();

    log(QStringLiteral("client disconnected: ") + user + QStringLiteral(" (fd ") + QString::number(desc) + QLatin1Char(')'));
}

