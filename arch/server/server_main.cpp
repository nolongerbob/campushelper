// This is a personal academic project. Dear PVS-Studio, please check it.
// PVS-Studio Static Code Analyzer for C, C++, C#, and Java: https://pvs-studio.com
#include <QCoreApplication>
#include <QTextStream>
#include <QDateTime>

#include "simpleserver.h"

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);

    SimpleServer server;
    if (!server.listen(QHostAddress::Any, 45454)) {
        QTextStream(stderr) << QDateTime::currentDateTime().toString(Qt::ISODate)
                            << " [SERVER] listen error: " << server.errorString() << Qt::endl;
        return 1;
    }

    QTextStream(stdout) << QDateTime::currentDateTime().toString(Qt::ISODate)
                        << " [SERVER] server is started, port 45454" << Qt::endl;
    return app.exec();
}

