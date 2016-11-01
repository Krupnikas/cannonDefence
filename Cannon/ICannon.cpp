#include "ICannon.h"

ICannon::ICannon(int i, int j,
               enum types typeOfCannon,
               Game *Window)
{
    window = Window;

    I = i;
    J = j;

    center = window->calculateCenterOfCannon(i, j);
    globalCenter = window->toGlobalPoint(center);

    type = typeOfCannon;
    angle = 0;
}

void ICannon::draw()
{
    switch (type)
    {
    case gun:
        barrelPen = bodyPen = QPen(QBrush("black"), 2);
        barrelBrush = QBrush("lightgrey");
        bodyBrush = QBrush("black");
        globalRadius = window->toGlobalDist(window->edgeOfPlaceSquare) / 5.0;
        drawGun();
        break;
    case bigGun:
        barrelPen = bodyPen = QPen(QBrush("black"), 2);
        barrelBrush = QBrush("lightgrey");
        bodyBrush = QBrush("black");
        globalRadius = window->toGlobalDist(window->edgeOfPlaceSquare) / 4.0;
        drawBigGun();
        break;
    case monsterGun:
        barrelPen = bodyPen = QPen(QBrush("black"), 2);
        barrelBrush = QBrush("lightgrey");
        bodyBrush = QBrush("black");
        globalRadius = window->toGlobalDist(window->edgeOfPlaceSquare) / 3.0;
        drawMonsterGun();
        break;
    case fireGun:
        barrelPen = bodyPen = QPen(QBrush(QColor(255, 160, 0)), 2);
        barrelBrush = QBrush("yellow");
        bodyBrush = QBrush(QColor(255, 160, 0));
        globalRadius = window->toGlobalDist(window->edgeOfPlaceSquare) / 4.0;
        drawFireGun();
        break;
    case plasmaGun:
        barrelPen = bodyPen = QPen(QBrush("darkcyan"), 2);
        barrelBrush = QBrush("cyan");
        bodyBrush = QBrush("darkcyan");
        globalRadius = window->toGlobalDist(window->edgeOfPlaceSquare) / 4.0;
        drawPlasmaGun();
        break;
    default:
        break;
    }
}

void ICannon::drawGun()
{
    QPolygon barrel;
    barrel << (globalCenter - QPoint(globalRadius * sin(angle),
                                     globalRadius * cos(angle)));
    barrel << (globalCenter + QPoint(1.5 * globalRadius * sin(angle - 1.0/5),
                                     1.5 * globalRadius * cos(angle - 1.0/5)));
    barrel << (globalCenter + QPoint(1.5 * globalRadius * sin(angle + 1.0/5),
                                     1.5 * globalRadius * cos(angle + 1.0/5)));
    window->gameScene.addPolygon(barrel,
                                 barrelPen,
                                 barrelBrush);
    window->gameScene.addEllipse(QRect(globalCenter
                                       - QPoint(globalRadius, globalRadius),
                                       globalCenter
                                       + QPoint(globalRadius, globalRadius)),
                                 bodyPen,
                                 bodyBrush);
}

void ICannon::drawBigGun()
{
    drawGun();
}

void ICannon::drawMonsterGun()
{
    drawGun();
}

void ICannon::drawFireGun()
{
    drawGun();
}

void ICannon::drawPlasmaGun()
{
    drawGun();
}
