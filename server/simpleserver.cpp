#include "simpleserver.h"

#include <QTextStream>
#include <QSqlQuery>
#include <QSqlError>

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

    m_db.setDatabaseName(QStringLiteral("campus_helper.db"));
    if (!m_db.open()) {
        QTextStream(stderr) << "db open error: " << m_db.lastError().text() << Qt::endl;
        return;
    }
    QTextStream(stdout) << "db is open" << Qt::endl;

    QSqlQuery q(m_db);
    if (!q.exec(QStringLiteral(
                    "CREATE TABLE IF NOT EXISTS users ("
                    " login TEXT PRIMARY KEY,"
                    " password TEXT NOT NULL,"
                    " role TEXT NOT NULL)"))) {
        QTextStream(stderr) << "db create table error: " << q.lastError().text() << Qt::endl;
    }

    if (!q.exec(QStringLiteral(
                    "INSERT OR IGNORE INTO users(login,password,role) VALUES"
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

            QTextStream(stdout) << "\"auth&" << QString::fromUtf8(login)
                                << "&" << QString::fromUtf8(pass) << "\"" << Qt::endl;

            if (m_db.isOpen()) {
                QTextStream(stdout) << "db is open" << Qt::endl;
            }

            if (parts.size() >= 2 && m_db.isOpen()) {
                QSqlQuery auth(m_db);
                auth.prepare(QStringLiteral(
                                 "SELECT role FROM users "
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
                    QTextStream(stdout) << "login = \"" << QString::fromUtf8(login)
                                       << "\" password = \"" << QString::fromUtf8(pass)
                                       << "\" result = \"authorization yes\"" << Qt::endl;
                } else {
                    socket->write("FAIL\n");
                    socket->flush();
                    QTextStream(stdout) << "login = \"" << QString::fromUtf8(login)
                                       << "\" password = \"" << QString::fromUtf8(pass)
                                       << "\" result = \"authorization error\"" << Qt::endl;
                }
            } else {
                socket->write("FAIL\n");
                socket->flush();
                QTextStream(stdout) << "login = \"" << QString::fromUtf8(login)
                                   << "\" password = \"" << QString::fromUtf8(pass)
                                   << "\" result = \"authorization error\"" << Qt::endl;
            }
            continue;
        }

        if (line.startsWith("LOGIN ")) {
            const QString user = QString::fromUtf8(line.mid(6));
            m_usernames[socket] = user;
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

    QTextStream(stdout) << "Client is disconnected \n";
}

