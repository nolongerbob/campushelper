#include "adduserdialog.h"

#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QLineEdit>
#include <QComboBox>
#include <QPushButton>
#include <QMessageBox>
#include <QTcpSocket>
#include <QHostAddress>

AddUserDialog::AddUserDialog(const QString &host, quint16 port, QWidget *parent)
    : QDialog(parent)
    , m_host(host)
    , m_port(port)
{
    setWindowTitle(QStringLiteral("Добавить пользователя в БД"));

    auto *mainLayout = new QVBoxLayout(this);

    auto *loginLayout = new QHBoxLayout;
    loginLayout->addWidget(new QLabel(QStringLiteral("Логин:")));
    m_loginEdit = new QLineEdit;
    m_loginEdit->setPlaceholderText(QStringLiteral("Новый логин"));
    loginLayout->addWidget(m_loginEdit);

    auto *passLayout = new QHBoxLayout;
    passLayout->addWidget(new QLabel(QStringLiteral("Пароль:")));
    m_passwordEdit = new QLineEdit;
    m_passwordEdit->setEchoMode(QLineEdit::Password);
    m_passwordEdit->setPlaceholderText(QStringLiteral("Пароль"));
    passLayout->addWidget(m_passwordEdit);

    auto *roleLayout = new QHBoxLayout;
    roleLayout->addWidget(new QLabel(QStringLiteral("Роль:")));
    m_roleCombo = new QComboBox;
    m_roleCombo->addItem(QStringLiteral("Студент"), QStringLiteral("student"));
    m_roleCombo->addItem(QStringLiteral("Преподаватель"), QStringLiteral("teacher"));
    roleLayout->addWidget(m_roleCombo);

    auto *buttonsLayout = new QHBoxLayout;
    auto *addBtn = new QPushButton(QStringLiteral("Добавить"));
    auto *cancelBtn = new QPushButton(QStringLiteral("Отмена"));
    buttonsLayout->addWidget(addBtn);
    buttonsLayout->addStretch();
    buttonsLayout->addWidget(cancelBtn);

    mainLayout->addLayout(loginLayout);
    mainLayout->addLayout(passLayout);
    mainLayout->addLayout(roleLayout);
    mainLayout->addLayout(buttonsLayout);

    connect(addBtn, &QPushButton::clicked, this, &AddUserDialog::onAddClicked);
    connect(cancelBtn, &QPushButton::clicked, this, &AddUserDialog::reject);
}

void AddUserDialog::onAddClicked()
{
    const QString login = m_loginEdit->text().trimmed();
    const QString password = m_passwordEdit->text();
    const QString role = m_roleCombo->currentData().toString();

    if (login.isEmpty() || password.isEmpty()) {
        QMessageBox::warning(this, QStringLiteral("Ошибка"),
                             QStringLiteral("Введите логин и пароль."));
        return;
    }

    QTcpSocket socket;
    socket.connectToHost(QHostAddress(m_host), m_port);
    if (!socket.waitForConnected(3000)) {
        QMessageBox::warning(this, QStringLiteral("Ошибка"),
                             QStringLiteral("Не удалось подключиться к серверу."));
        return;
    }

    QByteArray cmd = "ADDUSER " + login.toUtf8() + " " + password.toUtf8() + " " + role.toUtf8() + "\n";
    socket.write(cmd);
    socket.flush();

    if (!socket.waitForReadyRead(5000)) {
        QMessageBox::warning(this, QStringLiteral("Ошибка"),
                             QStringLiteral("Нет ответа от сервера."));
        return;
    }

    QByteArray reply = socket.readLine(512).trimmed();
    socket.disconnectFromHost();

    if (reply.startsWith("ADDUSER_OK")) {
        QMessageBox::information(this, QStringLiteral("Готово"),
                                 QStringLiteral("Пользователь «%1» добавлен в базу данных.").arg(login));
        accept();
        return;
    }

    QString msg = QString::fromUtf8(reply);
    if (msg.startsWith(QStringLiteral("ADDUSER_FAIL ")))
        msg = msg.mid(13);
    QMessageBox::warning(this, QStringLiteral("Ошибка добавления"), msg);
}
