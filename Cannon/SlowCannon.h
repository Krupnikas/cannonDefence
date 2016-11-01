#ifndef SLOWCANNON_H
#define SLOWCANNON_H

class SlowCannon : public ICannon
{
private:
    
public:
    
    virtual SlowCannon();
    virtual ~SlowCannon();
    
    virtual void draw() override;
    virtual void fire() override;
};

#endif // SLOWCANNON_H
