#ifndef LOGINDIALOG_H
#define LOGINDIALOG_H

#include <QDialog>

enum class UserRole {
    Guest,
    Student,
    Teacher
};

class QLineEdit;
class QComboBox;

class LoginDialog : public QDialog
{
    Q_OBJECT
public:
    explicit LoginDialog(QWidget *parent = nullptr);
    UserRole userRole() const;
    QString userName() const;

private slots:
    void onLoginClicked();
    void onGuestClicked();

private:
    QLineEdit *m_loginEdit;
    QLineEdit *m_passwordEdit;
    QComboBox *m_roleCombo;
    UserRole   m_role = UserRole::Guest;
};

#endif // LOGINDIALOG_H
