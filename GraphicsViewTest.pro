#-------------------------------------------------
#
# Project created by QtCreator 2016-10-17T16:23:45
#
#-------------------------------------------------

QT       += core gui

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = graphicsViewTest
TEMPLATE = app

CONFIG += c++11

SOURCES += main.cpp\
        game.cpp \
    cannon.cpp \
    enemy.cpp \
    bullet.cpp

HEADERS  += game.h \
    cannon.h \
    enemy.h \
    bullet.h

FORMS    += game.ui

unix|win32: LIBS += -L$$PWD/./ -lBox2D

INCLUDEPATH += $$PWD/Box2D
DEPENDPATH += $$PWD/Box2D

win32:!win32-g++: PRE_TARGETDEPS += $$PWD/./Box2D.lib
else:unix|win32-g++: PRE_TARGETDEPS += $$PWD/./libBox2D.a
