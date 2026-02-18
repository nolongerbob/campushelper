#include <QCoreApplication>
#include <QTextStream>

#include "simpleserver.h"

int main(int argc, char *argv[])
{
    QCoreApplication app(argc, argv);

    SimpleServer server;
    if (!server.listen(QHostAddress::Any, 45454)) {
        QTextStream(stderr) << "server listen error: " << server.errorString() << Qt::endl;
        return 1;
    }

    QTextStream(stdout) << "server is started" << Qt::endl;
    return app.exec();
}

