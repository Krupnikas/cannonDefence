#ifndef ENEMY_H
#define ENEMY_H

#include <Game/Game.h>

class enemy
{
public:

    enum types {
        solider,
        bigSolider,
        monsterSolider,
        smartSolider,
        fastSolider
    } type;

    enemy(enum types typeOfCannon,
          class game* Window);

    QPoint center;
    QPoint globalCenter;

    game* window;
};

#endif // ENEMY_H
