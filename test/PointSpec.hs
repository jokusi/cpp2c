{-# LANGUAGE TemplateHaskell #-}
module Main where

import qualified Foreign.Cpp.PointTest as PointTest

import Test.Tasty
import Test.Tasty.TH
import Test.Tasty.QuickCheck
import Test.Tasty.HUnit

main :: IO ()
main = $(defaultMainGenerator)

test_point :: [TestTree]
test_point =
  [ PointTest.tests
  ]
