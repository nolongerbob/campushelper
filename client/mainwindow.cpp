#include "mainwindow.h"
#include "ui_mainwindow.h"

#include <QTcpSocket>
#include <QTableWidget>
#include <QTableWidgetItem>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    setWindowTitle(QStringLiteral("АС «Campus Helper»"));

    m_socket = new QTcpSocket(this);
    connect(m_socket, &QTcpSocket::connected,
            this, &MainWindow::onServerConnected);
    connect(m_socket, &QTcpSocket::readyRead,
            this, &MainWindow::onServerReadyRead);

    connectToServer();
    setupDummyData();
}

MainWindow::~MainWindow()
{
    delete ui;
}

void MainWindow::setUserRole(UserRole role)
{
    m_role = role;
    applyRolePermissions();
}

void MainWindow::setUserName(const QString &name)
{
    m_userName = name;
}

void MainWindow::connectToServer()
{
    m_socket->connectToHost(QStringLiteral("127.0.0.1"), 45454);
}

void MainWindow::onServerConnected()
{
    QString roleStr;
    switch (m_role) {
    case UserRole::Student:  roleStr = QStringLiteral("student"); break;
    case UserRole::Teacher:  roleStr = QStringLiteral("teacher"); break;
    case UserRole::Guest:    roleStr = QStringLiteral("guest");   break;
    }

    QString loginInfo = m_userName.isEmpty() ? roleStr : m_userName;
    QByteArray loginCmd = "LOGIN " + loginInfo.toUtf8() + "\n";
    m_socket->write(loginCmd);
    m_socket->write("SCHEDULE\n");
}

void MainWindow::onServerReadyRead()
{
    QByteArray data = m_socket->readAll();
    QList<QByteArray> lines = data.split('\n');

    if (auto table = ui->tableSchedule) {
        table->clear();
        table->setColumnCount(3);
        QStringList headers = {QStringLiteral("Дата"),
                               QStringLiteral("Дисциплина"),
                               QStringLiteral("Аудитория")};
        table->setHorizontalHeaderLabels(headers);

        int row = 0;
        for (const QByteArray &line : lines) {
            QByteArray trimmed = line.trimmed();
            if (trimmed.isEmpty())
                continue;
            QList<QByteArray> parts = trimmed.split(';');
            if (parts.size() < 3)
                continue;
            table->insertRow(row);
            for (int col = 0; col < 3; ++col) {
                table->setItem(row, col,
                               new QTableWidgetItem(QString::fromUtf8(parts[col].trimmed())));
            }
            ++row;
        }
    }
}

void MainWindow::setupDummyData()
{
    if (auto table = ui->tableSchedule) {
        table->setColumnCount(3);
        QStringList headers = {QStringLiteral("Дата"),
                               QStringLiteral("Дисциплина"),
                               QStringLiteral("Аудитория")};
        table->setHorizontalHeaderLabels(headers);
        table->setRowCount(2);
        table->setItem(0, 0, new QTableWidgetItem(QStringLiteral("10.02.2026")));
        table->setItem(0, 1, new QTableWidgetItem(QStringLiteral("Математика")));
        table->setItem(0, 2, new QTableWidgetItem(QStringLiteral("А-101")));
        table->setItem(1, 0, new QTableWidgetItem(QStringLiteral("11.02.2026")));
        table->setItem(1, 1, new QTableWidgetItem(QStringLiteral("Программирование")));
        table->setItem(1, 2, new QTableWidgetItem(QStringLiteral("Б-202")));
    }
}

void MainWindow::applyRolePermissions()
{
    int resultsIndex = ui->tabWidget->indexOf(ui->tabResults);
    if (resultsIndex != -1) {
        bool showResults = (m_role != UserRole::Guest);
        ui->tabWidget->setTabVisible(resultsIndex, showResults);
    }
}
