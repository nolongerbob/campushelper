QT       += core network sql

CONFIG   += console
CONFIG   -= app_bundle

TEMPLATE = app
TARGET   = server

SOURCES += \
    server_main.cpp \
    simpleserver.cpp

HEADERS += \
    simpleserver.h

