# C++ with GHC #

This is a proof-of-concept of how to call a GCC generated C++ shared library with pure C code. This allows direct calls to a C++ library from GHC, which only supports C calls.

## The problem ##
To find functions inside a shared library (.so/.dll/.dylib), the function address is referenced by a plain ASCII string (symbols). This symbols are pretty much the same as the function names in a C header.

Inside the library there is no type information and one such symbol points exactly to one address. This is a problem for C++ function overloading. To deal with this problem, C++ uses something called [name mangling](https://en.wikipedia.org/wiki/Name_mangling). Basicly the type is also added to the library internal symbol. Additional C++ is also handling namespaces and classes by adding them to the internal symbol. If we want to call a C++ function from pure C code, the internal symbol of the functions needs to be known.

## About the project ##

### Content ###
- src: Haskell source code with use of the FFI.
- test: Haskell tests, that make use of the library.
- cppbits: C++ source code. Not actually needed to build the project. It is added as a reference.
- libPoint.so / Point.dll / libPoint.dylib: The shared library for Linux/Windows/OSX. In the following examples we will use `libPoint.so`. On other OS then Linux we need to replace it by the appropriate library.

### Compiling ###
This was tested with [Haskell Stack](http://docs.haskellstack.org/en/stable/README/), but should also build with cabal. On some Linux OS it is necessary to export the library path:

    $ export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:.

If we just want to compile C code and link it with the command, we can use:

    $ gcc -o <out_file_name> <c_src.c> -L. -lPoint

## Calling C++ library with C code ##
As an example, we use a simple Point class with integer x and y coordinates, constructors, getters and setters.

```
#!c++

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
        static int dimension(void);
    };
   
} // namespace point

#endif // __POINT_H__
```
We start by calling the static method `Point::dimension()`, which does nothing more then returning the value 2. After that we will simulate C++ object orientation on C level.

First we need all the internal names of the functions we want to use. We can calculate them by using a documentation on name mangling, but often it is easier to just use `nm`, which is part of GNU Binutils (which is also availible on Windows via [Msys2](https://msys2.github.io/)). Since the names still contain original namespace, class and function/method names, they can be filtered with `grep`, eg:

    $ nm libPoint.so | grep point

This will filter all methods from the `point` namespace .

### Functions and static methods ###
Beside the name mangling, there is no difference between C++ functions or static methods and C functions. They can be called normally from C. In this example we call the static method `Point::dimension()`.


```
#!C
#include <stdio.h>

// Declare mangled library function name.
extern int _ZN5point5Point9dimensionEv();

int main() {
    // Call external library function Point::dimension().
    printf("%d\n", _ZN5point5Point9dimensionEv()); // output: 2
}
```


### Object methods ###
Internally a dynamic method is nothing more like a normal C function with a pointer to the `this` object added as first parameter. Interestingly the same is true for constructors, which are actually not creating an objects (allocating memory), but instead only initializing the object, by setting its values. The object needs to be created before calling the constructor.

The problem is, what kind of objects should be used, if the original C++ type/class is not available? As long as we only access the object by its C++ methods, the only requirement is that both need to have the same size.

An easy way is to just use a `char` array of same size. 

```
#!c
#include <stdio.h>

// Constructor Point(int, int).
extern void _ZN5point5PointC1Eii(void *this, int x, int y);
// Method Pointer::getX();.
extern int _ZNK5point5Point4getXEv(void *this);

int main() {
    char pt[16];
    // Constructor call Point(3, 9).
    _ZN5point5PointC1Eii(&pt, 3, 9);
    // Method call pt.getX().
    printf("%d\n", _ZNK5point5Point4getXEv(&pt);
}
```

Another method is comparable to the use of the `new` operator on C++ side.

```
#!c
int main() {
    void *pt = malloc(16);
    // Constructor call Point(3, 9).
    _ZN5point5PointC1Eii(pt, 3, 9);
    // Method call pt.getX().
    printf("%d\n", _ZNK5point5Point4getXEv(pt);
    free(pt);
}
```

## Calling C++ library with Haskell FFI ##
The basic idea is, to use the FFI to give the mangled function a name on Haskell side. An advantage is, this name can be more readable, then the mangled version. The rest is just type marshalling. The FFI module should only export the marshalled functions.

### Static methods ###
Static methods are straight forward. First we need to import the C function.

```
#!haskell

foreign import ccall unsafe "_ZN5point5Point9dimensionEv"
  c_pointDimension :: CInt
```
And marshall it.

```
#!haskell

pointDimension :: Int
pointDimension = fromIntegral c_pointDimension
```

### Object methods ###
The major problem with object methods is the object creation itself. We need to allocate some memory similar to  the allocation method above. But we can use Haskells garbage collector to call the free function.

```
#!haskell
-- Haskell version of Point type. Do not export the constructor.
data Point   = Point (ForeignPtr Point)

-- C constructor function.
foreign import ccall unsafe "_ZN5point5PointC1Eii"
  c_pointCtor :: Ptr () -> CInt -> CInt -> IO ()

-- Haskell constructor function.
pointNew :: Int -> Int -> IO Point
pointNew x y = do
  -- Allocate memory
  ptr <- mallocBytes point3DSize
  -- Marshall Int to CInt and call c function.
  c_pointCtor (castPtr ptr) (fromIntegral x) (fromIntegral y)
  -- Link Haskell garbage collector to free function.
  fptr <- newForeignPtr finalizerFree ptr
  return $ Point fptr

```
When calling the object methods, a lot of marshalling has to be done.

```
#!haskell
-- C getX()
foreign import ccall unsafe "_ZNK5point5Point4getXEv"
  c_getX :: Ptr () -> IO CInt

-- Haskell getX
getX :: Point -> IO Int
getX (Point fptr) = withForeignPtr fptr $ \ptr -> do
  x <- c_getX $ castPtr ptr
  return $ fromIntegral x

-- C setX(int)
foreign import ccall unsafe "_ZN5point5Point4setXEi"
  c_setX :: Ptr () -> CInt -> IO ()

-- Hasekell setX
setX :: Point -> Int -> IO ()
setX (Point fptr) x = withForeignPtr fptr $ \ptr -> do
  c_setX (castPtr ptr) (fromIntegral x)
```

## Additional thoughts ##

### Using c2hs or other tools ###
Instead of directly implementing in Haskell, we could just make a C header with the mangled names. This can be used in combination with existing tools like c2hs to handle the marshalling.

### Other C++ compilers then GCC ###
This method should be possible with any C++ compiler. But the name mangling may differ. A look into the compiler documentation or the use of `nm` could give us the mangled names.

### Automatic generated files ###
Since doing this by hand is quite complicated, the best use of this method would be in combination with some automatic generator. It could parse the C++ header or use its own syntax like c2hs or similar tools. It should generate ready to use Haskell files.