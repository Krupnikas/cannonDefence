#-------------------------------------------------
#
# Project created by QtCreator 2016-10-17T16:23:45
#
#-------------------------------------------------

QT       += core gui

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = graphicsViewTest
TEMPLATE = app


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
