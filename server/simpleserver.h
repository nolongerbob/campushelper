#ifndef SIMPLESERVER_H
#define SIMPLESERVER_H

#include <QTcpServer>
#include <QTcpSocket>
#include <QMap>
#include <QSqlDatabase>

class SimpleServer : public QTcpServer
{
    Q_OBJECT
public:
    explicit SimpleServer(QObject *parent = nullptr);

protected:
    void incomingConnection(qintptr socketDescriptor) override;

private slots:
    void onReadyRead();
    void onDisconnected();

private:
    void initDatabase();

    QList<QTcpSocket*> m_clients;
    QMap<QTcpSocket*, QString> m_usernames;
    QMap<QTcpSocket*, QByteArray> m_readBuffers;
    QSqlDatabase m_db;
};

#endif // SIMPLESERVER_H

