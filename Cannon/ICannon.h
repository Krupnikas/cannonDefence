#ifndef CANNON_H
#define CANNON_H

#include <Game/Game.h>
namespace cannon 
{
    enum CannonType {
        SMALL, MEDIUM, BIG
    };
}


class ICannon
{    
    
private:
    double hp;
    double angle;
    double globalRadius;
    
    QPen bodyPen;
    QPen barrelPen;
    QBrush barrelBrush;
    QBrush bodyBrush;
    
    QPoint center;
    QPoint globalCenter;
    
    Game* window;
    
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

    virtual ICannon(int i, int j,
            cannon::CannonType cannon_type,
            Game* Window);
    virtual ~ICannon();

    virtual void draw();
    virtual void fire();
    
    void drawGun();
    void drawBigGun();
    void drawMonsterGun();
    void drawFireGun();
    void drawPlasmaGun();

};

#endif // CANNON_H
