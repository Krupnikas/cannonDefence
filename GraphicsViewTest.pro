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

SOURCES +=\
        game.cpp \
    cannon.cpp \
    enemy.cpp \
    bullet.cpp \
    Bullet/IBullet.cpp \
    Cannon/ICannon.cpp \
    Enemy/IEnemy.cpp \
    Game/Game.cpp \
    Cannon/SlowCannon.cpp \
    Game/common_h.cpp \
    Cannon/BurnCannon.cpp \
    Cannon/MonsterCannon.cpp

HEADERS  += game.h \
    cannon.h \
    enemy.h \
    bullet.h \
    Enemy/IEnemy.h \
    Cannon/ICannon.h \
    Game/Game.h \
    Bullet/IBullet.h \
    Cannon/SlowCannon.h \
    Game/common_h.h \
    Cannon/BurnCannon.h \
    Cannon/MonsterCannon.h

FORMS    += game.ui \
    Game/game.ui

unix|win32: LIBS += -L$$PWD/./ -lBox2D

INCLUDEPATH += $$PWD/Box2D
DEPENDPATH += $$PWD/Box2D

win32:!win32-g++: PRE_TARGETDEPS += $$PWD/./Box2D.lib
else:unix|win32-g++: PRE_TARGETDEPS += $$PWD/./libBox2D.a
