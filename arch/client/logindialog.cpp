#include "logindialog.h"

#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QLabel>
#include <QLineEdit>
#include <QComboBox>
#include <QPushButton>
#include <QMessageBox>
#include <QTcpSocket>
#include <QHostAddress>

LoginDialog::LoginDialog(QWidget *parent)
    : QDialog(parent)
{
    setWindowTitle(QStringLiteral("АС «Campus Helper» — вход"));

    auto *mainLayout = new QVBoxLayout(this);

    auto *loginLayout = new QHBoxLayout;
    loginLayout->addWidget(new QLabel(QStringLiteral("Логин:")));
    m_loginEdit = new QLineEdit;
    loginLayout->addWidget(m_loginEdit);

    auto *passLayout = new QHBoxLayout;
    passLayout->addWidget(new QLabel(QStringLiteral("Пароль:")));
    m_passwordEdit = new QLineEdit;
    m_passwordEdit->setEchoMode(QLineEdit::Password);
    passLayout->addWidget(m_passwordEdit);

    auto *roleLayout = new QHBoxLayout;
    roleLayout->addWidget(new QLabel(QStringLiteral("Роль:")));
    m_roleCombo = new QComboBox;
    m_roleCombo->addItem(QStringLiteral("Студент"));
    m_roleCombo->addItem(QStringLiteral("Преподаватель"));
    roleLayout->addWidget(m_roleCombo);

    auto *buttonsLayout = new QHBoxLayout;
    auto *loginBtn = new QPushButton(QStringLiteral("Войти"));
    auto *guestBtn = new QPushButton(QStringLiteral("Войти как гость"));
    auto *cancelBtn = new QPushButton(QStringLiteral("Отмена"));
    buttonsLayout->addWidget(loginBtn);
    buttonsLayout->addWidget(guestBtn);
    buttonsLayout->addStretch();
    buttonsLayout->addWidget(cancelBtn);

    mainLayout->addLayout(loginLayout);
    mainLayout->addLayout(passLayout);
    mainLayout->addLayout(roleLayout);
    mainLayout->addLayout(buttonsLayout);

    connect(loginBtn, &QPushButton::clicked,
            this, &LoginDialog::onLoginClicked);
    connect(guestBtn, &QPushButton::clicked,
            this, &LoginDialog::onGuestClicked);
    connect(cancelBtn, &QPushButton::clicked,
            this, &LoginDialog::reject);
}

UserRole LoginDialog::userRole() const
{
    return m_role;
}

QString LoginDialog::userName() const
{
    return m_loginEdit ? m_loginEdit->text().trimmed() : QString();
}

void LoginDialog::onLoginClicked()
{
    const QString login = m_loginEdit->text().trimmed();
    const QString password = m_passwordEdit->text();

    if (login.isEmpty() || password.isEmpty()) {
        QMessageBox::warning(this, QStringLiteral("Ошибка"),
                             QStringLiteral("Введите логин и пароль или выберите вход как гость."));
        return;
    }

    QTcpSocket socket;
    socket.connectToHost(QHostAddress(QStringLiteral("127.0.0.1")), 45454);
    if (!socket.waitForConnected(3000)) {
        QMessageBox::warning(this, QStringLiteral("Ошибка"),
                             QStringLiteral("Не удалось подключиться к серверу. Запустите сервер или войдите как гость."));
        return;
    }

    QByteArray authCmd = "AUTH " + login.toUtf8() + " " + password.toUtf8() + "\n";
    socket.write(authCmd);
    socket.flush();

    if (!socket.waitForReadyRead(3000)) {
        QMessageBox::warning(this, QStringLiteral("Ошибка"),
                             QStringLiteral("Нет ответа от сервера."));
        return;
    }

    QByteArray reply = socket.readLine(256).trimmed();
    socket.disconnectFromHost();

    if (reply.startsWith("OK ")) {
        QByteArray role = reply.mid(3).trimmed();
        if (role == "student")
            m_role = UserRole::Student;
        else if (role == "teacher")
            m_role = UserRole::Teacher;
        else
            m_role = UserRole::Student;
        accept();
        return;
    }

    QMessageBox::warning(this, QStringLiteral("Ошибка"),
                         QStringLiteral("Неверный логин или пароль.\n"
                                        "Доступные пользователи:\n"
                                        "student / student\n"
                                        "teacher / teacher"));
}

void LoginDialog::onGuestClicked()
{
    m_role = UserRole::Guest;
    accept();
}
