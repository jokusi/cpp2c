{-# LANGUAGE TemplateHaskell #-}
module Foreign.Cpp.PointTest (tests) where

import Foreign.Cpp.Point

import Test.Tasty
import Test.Tasty.TH
import Test.Tasty.QuickCheck
import Test.Tasty.HUnit
import Data.Function ((&))

tests :: TestTree
tests = $(testGroupGenerator)

case_call_statics :: Assertion
case_call_statics = do
  pointDimension @?= 2
  point3DDimension @?= 3

case_point_zero :: Assertion
case_point_zero = do
  let xVal = 2
      yVal = 5
  pt <- pointZeroNew
  pt & setX $ xVal
  pt & setY $ yVal
  x <- pt & getX
  y <- pt & getY
  x @?= xVal
  y @?= yVal

case_point :: Assertion
case_point = do
  let xVal = 2
      yVal = 5
  pt <- pointNew xVal yVal
  x <- pt & getX
  y <- pt & getY
  x @?= xVal
  y @?= yVal

case_point3d_zero :: Assertion
case_point3d_zero = do
  let xVal = 2
      yVal = 5
      zVal = 9
  pt <- point3DZeroNew
  pt & setX $ xVal
  pt & setY $ yVal
  pt & setZ $ zVal
  x <- pt & getX
  y <- pt & getY
  z <- pt & getZ
  x @?= xVal
  y @?= yVal
  z @?= zVal

case_point3d :: Assertion
case_point3d = do
  let xVal = 2
      yVal = 5
      zVal = 9
  pt <- point3DNew xVal yVal zVal
  x <- pt & getX
  y <- pt & getY
  z <- pt & getZ
  x @?= xVal
  y @?= yVal
  z @?= zVal

