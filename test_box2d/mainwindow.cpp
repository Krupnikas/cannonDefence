#include "mainwindow.h"
#include "ui_mainwindow.h"

qreal fromB2(qreal value) {
    return value * SCALE;
}

qreal toB2(qreal value) {
    return value / SCALE;
}

Circle::Circle(b2World *world, qreal radius, QPointF initPos):
    QGraphicsEllipseItem(0)
{
    setRect(-fromB2(radius), -fromB2(radius), fromB2(radius) * 2, fromB2(radius) * 2);
    setBrush(QBrush(Qt::green));
    setPos(fromB2(initPos.x()), fromB2(initPos.y()));
    
    b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody;
    bodyDef.position.Set(initPos.x(), initPos.y());
    bodyDef.linearDamping = 0.2;
    
    body = world->CreateBody(&bodyDef);
    
    b2CircleShape shape;
    shape.m_radius = radius;
    
    b2Fixture *fixture = body->CreateFixture(&shape, 1.0f);
    fixture->SetRestitution(0.7f);
}

Circle::~Circle() {
    body->GetWorld()->DestroyBody(body);
}

void Circle::advance(int phase) {
    if (phase) {
        setPos(fromB2(body->GetPosition().x),
               fromB2(body->GetPosition().y));
    }
}

GroundRect::GroundRect(b2World *world, QSizeF size, QPointF initPos, qreal angle) {
    setRect(-fromB2(size.width() / 2), -fromB2(size.height()),
            fromB2(size.width()), fromB2(size.height()));
    setBrush(QBrush(Qt::gray));
    setPos(fromB2(initPos.x()), fromB2(initPos.y()));
    setRotation(angle);
    
    b2BodyDef bodyDef;
    bodyDef.type = b2_staticBody;
    bodyDef.position.Set(initPos.x(), initPos.y());
    bodyDef.angle = 3.14 * angle / 180;
    
    body = world->CreateBody(&bodyDef);
    
    b2PolygonShape shape;
    shape.SetAsBox(size.width() / 2, size.height() / 2);
    
    body->CreateFixture(&shape, 0.0f);
}

GroundRect::~GroundRect() {
    body->GetWorld()->DestroyBody(body);
}

Scene::Scene(qreal x, qreal y, qreal width, qreal height, b2World *world) :
    QGraphicsScene(fromB2(x), fromB2(y), fromB2(width), fromB2(height))
{
    this->world = world;
}

void Scene::advance() {
    world->Step(1.0f / 60.0, 6, 2);
    QGraphicsScene::advance();
}

void Scene::mousePressEvent(QGraphicsSceneMouseEvent *event) {
    addItem(new Circle(world, 0.2, 
                       QPointF(toB2(event->scenePos().x()),
                               toB2(event->scenePos().y()))));
}

MainWindow::MainWindow(QMainWindow *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    
    int w = 8;
    int h = 6;
    
    world = new b2World(b2Vec2(0.f, 10.f));
    scene = new Scene(0, 0, w, h, world);
    ui->graphicsView->setScene(scene);
    ui->graphicsView->setFixedSize(fromB2(w), fromB2(h));
    ui->graphicsView->setSceneRect(0, 0, fromB2(w), fromB2(h));
    //ui->graphicsView->fitInView(0, 0, fromB2(w), fromB2(h), Qt::KeepAspectRatio);
    
    
//    QGraphicsView view(&scene);
//    view.show();
    
    scene->addRect(scene->sceneRect());
    scene->addItem(new GroundRect(world, QSizeF(4, 0.1), QPointF(2, 1), 15));
    scene->addItem(new GroundRect(world, QSizeF(4, 0.1), QPointF(6, 2), -10));
    scene->addItem(new GroundRect(world, QSizeF(4, 0.1), QPointF(2, 3), 15));
    scene->addItem(new GroundRect(world, QSizeF(4, 0.1), QPointF(6, 4), -10));
    scene->addItem(new GroundRect(world, QSizeF(8, 0.1), QPointF(4, 5.95), 0));
    scene->addItem(new GroundRect(world, QSizeF(0.1, 1), QPointF(0.05, 5.5), 0));
    
    frameTimer = new QTimer(this);
    connect(frameTimer, SIGNAL(timeout()),
            scene, SLOT(advance()));
    frameTimer->start(1000/60);
    
}

MainWindow::~MainWindow()
{
    delete ui;
}
