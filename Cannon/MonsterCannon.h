#ifndef MONSTERCANNON_H
#define MONSTERCANNON_H

class MonsterCannon : public ICannon
{
private:
    
public:
    
    virtual MonsterCannon();
    virtual ~MonsterCannon();
    
    virtual void draw() override;
    virtual void fire() override;
};

#endif // MONSTERCANNON_H
