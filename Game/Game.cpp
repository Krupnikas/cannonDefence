#include "game.h"
#include "ui_game.h"

game::game(QWidget *parent) :
    QWidget(parent),
    ui(new Ui::game)
{
    ui->setupUi(this);
    this->setLayout(ui->mainLayout);
    ui->graphicsView->setRenderHint(QPainter::Antialiasing);

    edgeOfPlaceSquare = (MY_MAX_Y
                        - 4 * SPACING
                        - 2 * INDENT) / 5.0;

    ui->graphicsView->setBackgroundBrush(QBrush(QColor(200,200,200)));

    H_INDENT = (MY_MAX_X
                - 8 * edgeOfPlaceSquare
                - 7 * SPACING) / 2;

    pWorkingRectangle = new QRect(ui->graphicsView->geometry());

    gameTimer.setInterval(16);

    connect(&gameTimer,
            SIGNAL(timeout()),
            this,
            SLOT(newFrame()));

    counter = 0;
}

game::~game()
{
    delete ui;
}

void game::showEvent(QShowEvent *)
{/*
    calculateWorkingRectangle();

    gameScene.addRect(*pWorkingRectangle,
                      QPen(QColor(200,200,200)),
                      QBrush(QColor(200,200,200)));

    addPlacesToScene();
    addStartAndStopPlaces();
    ui->graphicsView->setScene(&gameScene);*/
}

void game::resizeEvent(QResizeEvent *)
{
    gameScene.clear();
    calculateWorkingRectangle();
    gameScene.addRect(*pWorkingRectangle,
                      QPen(QColor(200,200,200)),
                      QBrush(QColor(200,200,200)));
    addPlacesToScene();
    addStartAndStopPlaces();
    ui->graphicsView->setScene(&gameScene);
}

void game::mouseClicked(QPoint cursorPos)
{
    QPoint place = findNearestPlaceFrom(cursorPos);
    Cannon cannon(place.x(), place.y(),
                   (Cannon::types)(counter++ % 7),
                   this);
    cannon.angle = counter / 2.0;
    cannon.draw();
}

void game::newFrame()
{
    ui->graphicsView->setScene(&gameScene);
}

void game::mousePressEvent(QMouseEvent *e)
{
    mouseClicked(QPoint(e->x(), e->y()));
}

void game::addPlacesToScene()
{
    for (int i = 0; i < 8; i++)
    {
        for(int j = 0; j < 5; j++)
        {
            QRect temp;
            temp.setTopLeft(
                        toGlobalPoint(
                            calculateTopLeftOfPlace(i, j)));
            temp.setWidth(toGlobalDist(edgeOfPlaceSquare));
            temp.setHeight(toGlobalDist(edgeOfPlaceSquare));
            gameScene.addRect(temp,
                              QPen((i + j)%2 ? QColor(240,240,240) : QColor(230,230,230)),
                              QBrush((i + j)%2 ? QColor(240,240,240) : QColor(230,230,230)));
#ifdef TEST
            QGraphicsTextItem *text = gameScene.addText(QString::number(i + 8 * j));
            text->setPos(toGlobalPoint(calculateCenterOfCannon(i, j)));

            gameScene.addRect(QRect(toGlobalPoint(calculateCenterOfCannon(i, j)) - QPoint(1, 1),
                                    toGlobalPoint(calculateCenterOfCannon(i, j)) + QPoint(1, 1)),
                                    QPen("red"),
                                    QBrush("red"));
#endif
        }
    }
}

void game::addStartAndStopPlaces()
{
    QRect temp;
    temp.setLeft(ui->graphicsView->geometry().left());
    temp.setRight(pWorkingRectangle->left() + toGlobalDist(H_INDENT-1));
    temp.setTop(toGlobalY(INDENT
                + 3 * edgeOfPlaceSquare
                + 2 * SPACING));
    temp.setHeight(toGlobalDist(edgeOfPlaceSquare));
    gameScene.addRect(temp,
                      QPen(QColor(240,240,240)),
                      QBrush(QColor(240,240,240)));

    temp.setLeft(pWorkingRectangle->right() - toGlobalDist(H_INDENT));
    temp.setRight(ui->graphicsView->geometry().right());
    gameScene.addRect(temp,
                      QPen(QColor(230,230,230)),
                      QBrush(QColor(230,230,230)));
}

int game::toGlobalX(int myX)
{
    return pWorkingRectangle->left()
            + pWorkingRectangle->width() * myX / MY_MAX_X;
}

int game::toGlobalY(int myY)
{
    return pWorkingRectangle->bottom()
            - pWorkingRectangle->height() * myY / MY_MAX_Y;
}

int game::toGlobalDist(int myDist)
{
    double k;
    if (pWorkingRectangle->width() * 9 > pWorkingRectangle->height() * 16)
    {
        k = pWorkingRectangle->height()/ (double)MY_MAX_Y;
    }
    else
    {
        k = pWorkingRectangle->width() / (double)MY_MAX_X;
    }
    return myDist * k;
}

QPoint game::toGlobalPoint(QPoint myPoint)
{
    return QPoint(toGlobalX(myPoint.x()),
                  toGlobalY(myPoint.y()));
}

void game::calculateWorkingRectangle()
{
    *pWorkingRectangle = ui->graphicsView->geometry();
    QPoint centerOfGraphicsView = ui->graphicsView->geometry().center();

    if (pWorkingRectangle->width() * 9 > pWorkingRectangle->height() * 16)
    {
        int newWidth;
        newWidth = pWorkingRectangle->height() * 16.0/9;
        qDebug() << newWidth;
        pWorkingRectangle->setLeft(centerOfGraphicsView.x() - newWidth/2.0);
        pWorkingRectangle->setWidth(newWidth);
    }
    else
    {
        int newHeight;
        newHeight = pWorkingRectangle->width() * 9.0/16;
        pWorkingRectangle->setTop(centerOfGraphicsView.y() - newHeight/2.0);
        pWorkingRectangle->setHeight(newHeight);
    }
}

QPoint game::calculateCenterOfCannon(int i, int j)
{
    int y = INDENT
            + edgeOfPlaceSquare / 2
            + j * edgeOfPlaceSquare
            + j * SPACING;

    int x = H_INDENT
            + edgeOfPlaceSquare / 2
            + i * edgeOfPlaceSquare
            + i * SPACING;

    return QPoint(x, y);
}

QPoint game::calculateTopLeftOfPlace(int i, int j)
{
    int y = INDENT
            + (1 + j) * edgeOfPlaceSquare
            + j * SPACING;

    int x = H_INDENT
            + i * edgeOfPlaceSquare
            + i * SPACING;

    return QPoint(x, y);
}

QPoint game::findNearestPlaceFrom(QPoint globalPos)
{
    QPoint minPlace(0, 0);
    double squaredMinDist = pow(edgeOfPlaceSquare, 2);
    for(int i = 0; i < 8; i++)
    {
        for(int j = 0; j < 5; j++)
        {
            QPoint gC = toGlobalPoint(calculateCenterOfCannon(i, j));
            double squaredDist = pow(gC.x() - globalPos.x(), 2)
                               + pow(gC.y() - globalPos.y(), 2);
            if (squaredDist < squaredMinDist)
            {
                squaredMinDist = squaredDist;
                minPlace = QPoint(i, j);
            }
        }
    }

#ifdef TEST
    QPoint minGP = toGlobalPoint(calculateCenterOfCannon(minPlace.x(),
                                                         minPlace.y()));
    gameScene.addLine(globalPos.x(),
                      globalPos.y(),
                      minGP.x(),
                      minGP.y(),
                      QPen("red"));
#endif
    return minPlace;
}
