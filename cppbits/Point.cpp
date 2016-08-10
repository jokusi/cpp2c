#include "Point.h"
#include <iostream>
#include <string>

using std::wstring;
using std::wcout;
using std::endl;

namespace point {

Point::Point() : x(0), y(0) {}
Point::Point(int x, int y) : x(x), y(y) {}

int Point::getX() const { return x; }
void Point::setX(int x) { this->x = x; }

int Point::getY() const { return y; }
void Point::setY(int y) { this->y = y; }

int Point::dimension() { return 2; }

void Point::print() const {
    wcout << L"Point(" << x << L", " << y << L")" << endl;
}

Point3D::Point3D() : Point(), z(0) {}
Point3D::Point3D(int x, int y, int z) : Point(x, y), z(z) {}

int Point3D::getZ() const { return z; }
void Point3D::setZ(int z) { this->z = z; }

int Point3D::dimension() { return 3; }

void Point3D::print() const {
    wcout << L"Point3D(" << this->getX()
        << L", " << this->getY()
        << L", " << z << L")" << endl;
}

} // namespace point