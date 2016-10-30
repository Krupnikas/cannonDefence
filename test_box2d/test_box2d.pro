#-------------------------------------------------
#
# Project created by QtCreator 2016-10-30T04:50:48
#
#-------------------------------------------------

QT       += core gui

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = test_box2d
TEMPLATE = app
CONFIG += c++11

SOURCES += main.cpp\
        mainwindow.cpp

HEADERS  += mainwindow.h

FORMS    += mainwindow.ui

INCLUDEPATH += $$PWD/Box2D
DEPENDPATH += $$PWD/Box2D

unix|win32: LIBS += -L$$PWD/./ -lBox2D

INCLUDEPATH += $$PWD/Box2D
DEPENDPATH += $$PWD/Box2D

win32:!win32-g++: PRE_TARGETDEPS += $$PWD/./Box2D.lib
else:unix|win32-g++: PRE_TARGETDEPS += $$PWD/./libBox2D.a
