import System.TimeIt

import Foreign.Ptr (nullPtr)
import Foreign.C.Types

import Options.Applicative
import Control.Monad

import Data.Number.Flint.Arb

main = timeItNamed "time"
     $ run =<< customExecParser (prefs showHelpOnEmpty) opts where
  opts = info (parameters <**> helper) (
         fullDesc
      <> progDesc "Calculates digits of pi."
      <> header "Calculates digits of pi.")

run (Parameters digits condense) = do
  let prec = floor $ fromIntegral digits / logBase 10 2 + 5
      flag = foldr (+) arb_str_none $
                   replicate condense arb_str_condense
  putStrLn $ "computing pi with a precision of " ++ show prec ++ " bits ..."
  withNewArb $ \x -> do
    arb_const_pi x prec
    arb_printn x (fromIntegral digits) flag
    putStr "\n"
    
data Parameters = Parameters {
  digits :: Int,
  condense :: Int
} deriving Show

parameters :: Parser Parameters
parameters = Parameters
  <$> argument auto (
    help "number of digits to calculate." <>
    metavar "digits")
  <*> argument auto (
    value 20 <>
    help "condense" <>
    showDefault <>
    metavar "condense")
    