#ifndef CONFIG_H
#define CONFIG_H

#include <QString>
#include <QByteArray>

// Адрес stage-сервера: можно задать через переменную окружения CAMPUS_HELPER_SERVER_HOST
// По умолчанию: localhost (для локальной разработки)
// Для подключения к stage: export CAMPUS_HELPER_SERVER_HOST=IP_STAGE_СЕРВЕРА
inline QString getServerHost() {
    const QByteArray envHost = qgetenv("CAMPUS_HELPER_SERVER_HOST");
    if (!envHost.isEmpty())
        return QString::fromUtf8(envHost);
    return QStringLiteral("127.0.0.1");  // localhost по умолчанию
}

constexpr quint16 SERVER_PORT = 45454;

#endif // CONFIG_H
