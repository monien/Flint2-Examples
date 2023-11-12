import System.FilePath

import Data.List (intercalate)
import qualified Data.Map as Map

import Control.Monad

import Options.Applicative

import Codec.Picture
import Graphics.Gloss 
import Graphics.Gloss.Juicy

import ColorFunction
import Functions

main :: IO ()
main = run =<< execParser opts where
  opts = info (parameters <**> helper) 
       ( fullDesc
      <> progDesc "\nplotting special functions.\n"
      <> header "Plotting special functions in the complex plane.")

run :: Parameters -> IO ()
run (Parameters xa xb ya yb w h colorMode f imgFile num_threads) = do
  when (colorMode < 0 || colorMode > 6) $ do error "colorMode not available."
  case Map.lookup f functions of 
    Just g -> do let u i j = evalSafe (xa, xb, w) (ya, yb, h) g i (h-j)
                     v i j = rgba colorMode (u i j)
                     img = ImageRGBA8 (generateImage v w h)
                 case imgFile of
                   Just out -> saveImage out img
                   _ -> return ()
                 case fromDynamicImage img of
                   Just picture -> display (InWindow "arb plot" (w, h) (0, 0))
                                           white picture
                   _ -> putStrLn "could not display picture."
    _ -> putStrLn $ "function '" ++ f ++ "' not available."

rgba colorMode z = PixelRGBA8 r' g' b' alpha where
  (r, g, b) = colorFunction colorMode z
  alpha = if (r, g, b) /= (0.5, 0.5, 0.5) then 255 else 0
  [r', g', b'] = map (min 255 . floor . (*255)) [r, g, b]

saveImage out img = do
  if hasExtension out then do
    let f = case takeExtension out of
              ".bmp"  -> Just saveBmpImage
              ".png"  -> Just savePngImage
              ".jpg"  -> Just (saveJpgImage 100)
              ".tiff" -> Just saveTiffImage
              ".hdr"  -> Just saveRadianceImage
              _       -> Nothing
    case f of
      Just f -> do f out img
                   return ()
      _ -> putStrLn "Could not save image: unknown file extension.\n\
                    \Use bmp, jpg, png, tiff or hdr as file extension." 
  else
    putStrLn "Could not save image: no file extension.\n\
             \Use bmp, jpg, png, tiff or hdr as file extension." 
    
data Range = Range Double Double Double Double deriving Show
data Size = Size Int Int deriving Show

data Parameters = Parameters {
    xa :: Double
  , xb :: Double
  , ya :: Double
  , yb :: Double
  , with :: Int
  , height :: Int
  , colorMode :: Int
  , fun :: String
  , imgFile :: Maybe String
  , num_threads :: Int
  } deriving Show

parameters :: Parser Parameters
parameters = Parameters
  <$> option auto (
      long "xa" <>
      value (-1.0) <>
      showDefault <>
      metavar "XA")
  <*> option auto (
      long "xb" <>
      value 1.0 <>
      showDefault <>
      metavar "XB")
  <*> option auto (
      long "ya" <>
      value 0.0 <>
      showDefault <>
      metavar "YA") 
  <*> option auto (
      long "yb" <>
      value 2 <>
      showDefault <>
      metavar "YB")
  <*> option auto (
      long "width" <>
      -- short 'w' <>
      value 512 <>
      showDefault <>
      metavar "WIDTH")
  <*> option auto (
      long "height" <>
      -- short 'h' <>
      value 512 <>
      showDefault <>
      metavar "HEIGHT")
  <*> option auto (
      long "color-mode" <>
      short 'c' <>
      value 0 <>
      help ("possible values: 0 .. 6") <>
      metavar "COLOR-MODE")
  <*> strOption (
      short 'f' <>
      long "function" <>
      value "modj" <> 
      help ("possible values: " ++ intercalate ", " (Map.keys functions)) <>
      metavar "FUNCTION")
  <*> optional (strOption (
      long "output" <>
      short 'o' <>
      metavar "IMAGE-FILE" <>
      help "write output to IMAGE-FILE"))
  <*> option auto (
      help "number of threads"
   <> long "threads"
   <> value 1
   <> metavar "THREADS")