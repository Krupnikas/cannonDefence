#ifndef BULLET_H
#define BULLET_H

#include <game.h>

class bullet
{
public:

    enum types {
        shot,
        bigShot,
        monsterShot,
        fireShot,
        plasmaShot
    } type;

    bullet();
};

#endif // BULLET_H
