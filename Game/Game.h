#ifndef GAME_H
#define GAME_H
//#define TEST

#include <QWidget>
#include <QGraphicsScene>
#include <QDebug>
#include <QGraphicsTextItem>
#include <QMouseEvent>
#include <QTimer>
#include <QPoint>
#include <qmath.h>

#include <Cannon/ICannon.h>
#include <Enemy/IEnemy.h>
#include <Bullet/IBullet.h>

namespace Ui {
class Game;
}

class Game : public QWidget
{
    Q_OBJECT

    const int MY_MAX_X = 1600;
    const int MY_MAX_Y = 900;

    int H_INDENT;

    const int INDENT = 6;
    const int SPACING = 0;

public:
    explicit Game(QWidget *parent = 0);
    ~Game();

    QGraphicsScene gameScene;
    QRect* pWorkingRectangle;

    QTimer gameTimer;

    int edgeOfPlaceSquare;
    int counter;

    void showEvent(QShowEvent *);
    void resizeEvent(QResizeEvent *);
    void mousePressEvent(QMouseEvent *e);

    void addPlacesToScene();
    void addStartAndStopPlaces();
    void calculateWorkingRectangle();

    int toGlobalX(int myX);
    int toGlobalY(int myY);
    int toGlobalDist(int myDist);
    QPoint toGlobalPoint(QPoint myPoint);

    QPoint calculateCenterOfCannon(int i, int j);
    QPoint calculateTopLeftOfPlace(int i, int j);
    QPoint findNearestPlaceFrom(QPoint globalPos);

public slots:

    void mouseClicked(QPoint cursorPos);
    void newFrame();

private:
    Ui::Game *ui;   
};

#endif // GAME_H
