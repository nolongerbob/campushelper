#include <QApplication>

#include "mainwindow.h"
#include "logindialog.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    LoginDialog login;
    if (login.exec() != QDialog::Accepted)
        return 0;

    MainWindow w;
    w.setUserRole(login.userRole());
    w.setUserName(login.userName());
    w.show();

    return app.exec();
}
