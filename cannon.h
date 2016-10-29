#ifndef CANNON_H
#define CANNON_H

#include <game.h>

class Cannon
{    
public:

    enum types {
        empty,
        wall,
        gun,
        bigGun,
        monsterGun,
        fireGun,
        plasmaGun
    } type;

    Cannon(int i, int j,
           enum types typeOfCannon,
           class game* Window);

    int I;
    int J;

    QPoint center;
    QPoint globalCenter;

    QPen bodyPen;
    QPen barrelPen;
    QBrush barrelBrush;
    QBrush bodyBrush;

    game* window;

    double hp;
    double angle;
    double globalRadius;

    void draw();
    void drawGun();
    void drawBigGun();
    void drawMonsterGun();
    void drawFireGun();
    void drawPlasmaGun();

};

#endif // CANNON_H
