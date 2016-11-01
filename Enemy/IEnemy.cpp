#include "IEnemy.h"

IEnemy::IEnemy(types typeOfCannon, Game *Window)
{
    type = typeOfCannon;
    window = Window;
}
