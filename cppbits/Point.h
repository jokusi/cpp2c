#ifndef __POINT_H__
#define __POINT_H__

namespace point {
    
    class Point {
    private:
        int x, y;
    public:
        Point(void);
        Point(int x, int y);
        int getX(void) const;
        void setX(int x);
        int getY(void) const;
        void setY(int y);
        virtual void print(void) const;
        static int dimension(void);
    };
    
    class Point3D : public Point {
    private:
        int z;
    public:
        Point3D(void);
        Point3D(int x, int y, int z);
        int getZ(void) const;
        void setZ(int z);
        void print(void) const;
        static int dimension(void);
    };
    
    
} // namespace point

#endif // __POINT_H__