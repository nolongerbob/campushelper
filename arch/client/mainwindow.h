#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include "logindialog.h"

QT_BEGIN_NAMESPACE
namespace Ui { class MainWindow; }
QT_END_NAMESPACE

class QAction;
class QTcpSocket;

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

    void setUserRole(UserRole role);
    void setUserName(const QString &name);

private slots:
    void onServerConnected();
    void onServerReadyRead();
    void onAddUserTriggered();

private:
    void setupDummyData();
    void connectToServer();
    void applyRolePermissions();

    Ui::MainWindow *ui;
    UserRole m_role = UserRole::Guest;
    QTcpSocket *m_socket = nullptr;
    QString m_userName;
    QAction *m_actionAddUser = nullptr;
};

#endif // MAINWINDOW_H
