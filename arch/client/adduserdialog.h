#ifndef ADDUSERDIALOG_H
#define ADDUSERDIALOG_H

#include <QDialog>

class QLineEdit;
class QComboBox;

class AddUserDialog : public QDialog
{
    Q_OBJECT
public:
    explicit AddUserDialog(const QString &host, quint16 port, QWidget *parent = nullptr);

private slots:
    void onAddClicked();

private:
    QLineEdit *m_loginEdit = nullptr;
    QLineEdit *m_passwordEdit = nullptr;
    QComboBox *m_roleCombo = nullptr;
    QString m_host;
    quint16 m_port;
};

#endif // ADDUSERDIALOG_H
