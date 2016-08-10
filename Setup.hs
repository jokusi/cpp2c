import Distribution.Simple
import Distribution.Simple.Setup
import Distribution.Simple.LocalBuildInfo
import Distribution.PackageDescription
import System.Directory (getCurrentDirectory)

main = defaultMainWithHooks simpleUserHooks { confHook = myConfHook }

myConfHook :: (GenericPackageDescription, HookedBuildInfo) -> ConfigFlags -> IO LocalBuildInfo
myConfHook info flags = do
  lbi <- confHook simpleUserHooks info flags
  cd <- getCurrentDirectory
  let lpd        = localPkgDescr lbi
  let Just lib   = library lpd
  let libbi      = libBuildInfo lib
  let libbi' = libbi { extraLibDirs = cd : extraLibDirs libbi }
  let lib' = lib { libBuildInfo = libbi' }
  let lpd' = lpd { library = Just lib' }
  return $ lbi { localPkgDescr = lpd' }

