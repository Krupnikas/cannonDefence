#ifndef BURNCANNON_H
#define BURNCANNON_H

class BurnCannon : public ICannon
{
private:
    
public:
    
    virtual BurnCannon();
    virtual ~BurnCannon();
    
    virtual void draw() override;
    virtual void fire() override;
};

#endif // BURNCANNON_H
