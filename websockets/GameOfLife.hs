import Char
import Web
import Network
import System.IO

import Data.Array
import Data.List.Split

data Cell = Off 
          | On 
          | Dying
          deriving (Show)

-- For marshalling back and forth to JSON
-- this is embarassingly shite
cellToChar :: Cell -> Char
cellToChar Off = '0'
cellToChar On = '1'
cellToChar Dying = '2' 

charToCell :: Char -> Cell
charToCell '0' = Off
charToCell '1' = On
charToCell '2' = Dying
charToCell x = error "Undefined character received"

type GameGrid = Array (Int,Int) Cell

createGrid :: Int -> [Cell] -> GameGrid
createGrid x = listArray ((0,0),(x,x))

processMessage :: String -> String
processMessage s = s where
    [cellSize,grid] = lines s

listenLoop :: Handle -> IO ()
listenLoop h = do
  msg <- readFrame h
  sendFrame h (processMessage msg)
  listenLoop h
  

main = serverListen 9876 listenLoop


