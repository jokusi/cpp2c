{-# LANGUAGE ForeignFunctionInterface #-}
module Foreign.Cpp.Point
  ( pointDimension
  , point3DDimension
  , Point
  , Point3D
  , pointNew
  , pointZeroNew
  , point3DNew
  , point3DZeroNew
  , setX
  , setY
  , setZ
  , getX
  , getY
  , getZ
  ) where

import Foreign.C
import Foreign.Marshal.Alloc
import Foreign.ForeignPtr
import Foreign.Ptr

-- cpp calls

foreign import ccall unsafe "_ZN5point5Point9dimensionEv"
  c_pointDimension :: CInt

foreign import ccall unsafe "_ZN5point7Point3D9dimensionEv"
  c_point3DDimension :: CInt

foreign import ccall unsafe "_ZN5point5PointC1Ev"
  c_pointZeroCtor :: Ptr () -> IO ()

foreign import ccall unsafe "_ZN5point5PointC1Eii"
  c_pointCtor :: Ptr () -> CInt -> CInt -> IO ()

foreign import ccall unsafe "_ZN5point7Point3DC1Ev"
  c_point3DZeroCtor :: Ptr () -> IO ()

foreign import ccall unsafe "_ZN5point7Point3DC1Eiii"
  c_point3DCtor :: Ptr () -> CInt -> CInt -> CInt -> IO ()

foreign import ccall unsafe "_ZNK5point5Point4getXEv"
  c_getX :: Ptr () -> IO CInt

foreign import ccall unsafe "_ZNK5point5Point4getYEv"
  c_getY :: Ptr () -> IO CInt

foreign import ccall unsafe "_ZNK5point7Point3D4getZEv"
  c_getZ :: Ptr () -> IO CInt

foreign import ccall unsafe "_ZN5point5Point4setXEi"
  c_setX :: Ptr () -> CInt -> IO ()

foreign import ccall unsafe "_ZN5point5Point4setYEi"
  c_setY :: Ptr () -> CInt -> IO ()

foreign import ccall unsafe "_ZN5point7Point3D4setZEi"
  c_setZ :: Ptr () -> CInt -> IO ()



-- static

pointDimension :: Int
pointDimension = fromIntegral c_pointDimension

point3DDimension :: Int
point3DDimension = fromIntegral c_point3DDimension

-- Point data
pointSize, point3DSize :: Int
pointSize   = 16
point3DSize = 32

data Point   = Point (ForeignPtr Point)
data Point3D = Point3D (ForeignPtr Point3D)

class PointClass point where
  toPoint :: point -> Point

instance PointClass Point where
  toPoint = id

instance PointClass Point3D where
  toPoint (Point3D fptr) = Point $ castForeignPtr fptr

class Point3DClass point3d where
  toPoint3D :: point3d -> Point3D

instance Point3DClass Point3D where
  toPoint3D = id

allocPoint :: IO (ForeignPtr Point)
allocPoint = do
  ptr <- mallocBytes pointSize
  fptr <- newForeignPtr finalizerFree ptr
  return $ fptr

allocPoint3D :: IO (ForeignPtr Point3D)
allocPoint3D = do
  ptr <- mallocBytes point3DSize
  fptr <- newForeignPtr finalizerFree ptr
  return $ fptr

pointNew :: Int -> Int -> IO Point
pointNew x y = do
  fpt <- allocPoint
  withForeignPtr fpt $ \pt -> do
    c_pointCtor (castPtr pt) (fromIntegral x) (fromIntegral y)
  return $ Point fpt

pointZeroNew :: IO Point
pointZeroNew = do
  fpt <- allocPoint
  withForeignPtr fpt $ \pt -> do
    c_pointZeroCtor $ castPtr pt
  return $ Point fpt

point3DNew :: Int -> Int -> Int -> IO Point3D
point3DNew x y z = do
  fpt <- allocPoint3D
  withForeignPtr fpt $ \pt -> do
    c_point3DCtor (castPtr pt) (fromIntegral x) (fromIntegral y) (fromIntegral z)
  return $ Point3D fpt

point3DZeroNew :: IO Point3D
point3DZeroNew = do
  fpt <- allocPoint3D
  withForeignPtr fpt $ \pt -> do
    c_point3DZeroCtor $ castPtr pt
  return $ Point3D fpt

getX, getY :: PointClass point => point -> IO Int
getX ptcl = withForeignPtr fpt $ \pt -> do
  x <- c_getX $ castPtr pt
  return $ fromIntegral x
  where (Point fpt) = toPoint ptcl
  
getY ptcl = withForeignPtr fpt $ \pt -> do
  y <- c_getY $ castPtr pt
  return $ fromIntegral y
  where (Point fpt) = toPoint ptcl

getZ :: Point3DClass point3d => point3d -> IO Int
getZ ptcl = withForeignPtr fpt $ \pt -> do
  z <- c_getZ $ castPtr pt
  return $ fromIntegral z
  where (Point3D fpt) = toPoint3D ptcl

setX, setY :: PointClass point => point -> Int -> IO ()
setX ptcl x = withForeignPtr fpt $ \pt -> do
  c_setX (castPtr pt) (fromIntegral x)
  where (Point fpt) = toPoint ptcl
  
setY ptcl y = withForeignPtr fpt $ \pt -> do
  c_setY (castPtr pt) (fromIntegral y)
  where (Point fpt) = toPoint ptcl

setZ :: Point3DClass point3d => point3d -> Int -> IO ()
setZ ptcl z = withForeignPtr fpt $ \pt -> do
  c_setZ (castPtr pt) (fromIntegral z)
  where (Point3D fpt) = toPoint3D ptcl
