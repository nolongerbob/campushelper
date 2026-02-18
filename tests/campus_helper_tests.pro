# Лабораторная работа 7 — юнит-тесты (QTestLib)
QT += testlib
QT -= gui
QT += sql core

CONFIG += qt console warn_on depend_includepath testcase
CONFIG -= app_bundle

TEMPLATE = app
TARGET = campus_helper_tests

SOURCES += \
    tst_auth.cpp \
    ../server/authcheck.cpp

HEADERS += \
    ../server/authcheck.h

INCLUDEPATH += $$PWD/../server

# выход из тестов с кодом 0 только если все тесты прошли
QMAKE_CXXFLAGS += -DQTEST_NO_MAIN_RETURN_CODE
