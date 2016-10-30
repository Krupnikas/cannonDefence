#include "game.h"
#include <QApplication>
#include <Box2D.h>

int main(int argc, char *argv[])
{
    
    QApplication a(argc, argv);
    game w;
    w.show();

    return a.exec();
}
