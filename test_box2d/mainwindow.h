#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QPointF>
#include <QWidget>
#include <QGraphicsView>
#include <QGraphicsScene>
#include <QGraphicsSceneMouseEvent>
#include <QGraphicsEllipseItem>
#include <QTimer>
#include <Box2D.h>

const qreal SCALE = 100;

namespace Ui {
class MainWindow;
}

class Circle : public QGraphicsEllipseItem {
public:
    Circle(b2World *world, qreal radius, QPointF initPos);
    ~Circle();
private:
    b2Body *body;
public:
    virtual void advance(int phase);
};

class GroundRect : public QGraphicsRectItem {
public:
    GroundRect(b2World *world, QSizeF size, QPointF initPos, qreal angle);
    ~GroundRect();
private:
    b2Body *body;
};

class Scene : public QGraphicsScene {
    Q_OBJECT
public:
    Scene(qreal x, qreal y, qreal width, qreal height, b2World *world);
public slots:
    void advance();
private:
    b2World *world;
    
protected:
    virtual void mousePressEvent(QGraphicsSceneMouseEvent *event);
};

class MainWindow : public QMainWindow
{
    Q_OBJECT
    
public:
    explicit MainWindow(QMainWindow *parent = 0);
    ~MainWindow();
    
private:
    Ui::MainWindow *ui;
    Scene *scene;
    QTimer *frameTimer;
    b2World *world;
};

#endif // MAINWINDOW_H
