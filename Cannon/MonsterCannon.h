#ifndef SLOWCANNON
#define SLOWCANNON

#endif // SLOWCANNON


class SlowCannon : public ICannon
{
private:
    
public:
    
    virtual SlowCannon();
    virtual ~SlowCannon();
    
    virtual void draw() override;
    virtual void fire() override;
};
