import Options.Applicative
import Control.Monad
import Foreign.C.Types
import Data.Time
import System.TimeIt

import Data.Number.Flint

main = timeItNamed "time"
     $ run =<< customExecParser (prefs showHelpOnEmpty) opts where
  desc = "Calculates bernoulli numbers."
  opts = info (parameters <**> helper) (
         fullDesc
      <> progDesc desc
      <> header desc)

run params@(Parameters n display num_threads) = do
  flint_set_num_threads num_threads
  x <- newFmpq
  withFmpq x $ \x -> bernoulli_fmpq_ui x n
  when (n <= 100 || display) $ print x
  
data Parameters = Parameters {
    n :: CULong
  , display :: Bool
  , num_threads :: CInt
} deriving Show

parameters :: Parser Parameters
parameters = Parameters
  <$> argument auto (
      help "n"
   <> metavar "n")
  <*> switch (
      help "display value"
   <> short 'd')
  <*> option auto (
      help "number of threads"
   <> long "threads"
   <> value 1
   <> metavar "threads")
