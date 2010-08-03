module ChaseVis where

import Chase

import Graphics.UI.GLUT as G
import System.Exit (exitWith, ExitCode(ExitSuccess))
import Control.Monad (when,unless,forM_,liftM,liftM2,liftM3)
import Data.IORef (IORef, newIORef)

import Data.Map ((!))
import qualified Data.Map as M

data State = State {
      env :: IORef Environment
    , run :: IORef Bool
}

-- Various top-level configuration parameters

gridSize :: Int
gridSize = 16

winHeight :: Int
winHeight = 512

winWidth :: Int
winWidth = 512

tick :: Int
tick = 25

sqSize :: GLfloat
sqSize = fromIntegral winHeight / fromIntegral gridSize

makeState :: IO State
makeState = liftM2 State (newIORef (createEnvironment gridSize)) (newIORef False)

color3f :: Color3 GLfloat -> IO ()
color3f = color

vertex2f :: Vertex2 GLfloat -> IO ()
vertex2f = vertex :: Vertex2 GLfloat -> IO ()

colorVertex :: Color3 GLfloat ->  Vertex2 GLfloat -> IO ()  
colorVertex c v = color3f c >> vertex v

-- Actual logic of environment appears here

displayFunc :: State -> DisplayCallback
displayFunc s = do
  clear [ColorBuffer]
  e <- G.get (env s)
  _ <- drawGrid e 
  flush
  swapBuffers

pickColor :: Agent -> Color3 GLfloat
pickColor (Goal s) = Color3 (realToFrac s) 0 0
pickColor (Pursuer s) = Color3 0 1 0
pickColor (Path s) = Color3 0 0 (realToFrac s)
pickColor Obstacle = Color3 1 1 1

drawGrid :: Environment -> IO ()
drawGrid (Environment g b _ _) = do
  lineWidth $= realToFrac 0.1
  let f i = ((fromIntegral i - 0.5 :: GLfloat) * sqSize)
  renderPrimitive Quads $ forM_ [(x,y) | x <- [0..b], y <- [0..b]]
                      (\(i,j) -> mapM (colorVertex (pickColor (top $ g ! (i,j))))
                                      [Vertex2 (f i + x) (f j + y) | (x,y) <- [(0,0),(sqSize,0),(sqSize,sqSize),(0,sqSize)]])
  flush
    

timerFunc :: State -> IO ()
timerFunc s = do
  e <- G.get (run s)
  when e (env s $~ update)
  postRedisplay Nothing
  addTimerCallback tick (timerFunc s)

reshapeFunc :: ReshapeCallback
reshapeFunc s@(Size _ height) = 
    unless (height == 0) $ do
      viewport $= (Position 0 0, s)
      loadIdentity
      ortho2D 0 512 0 512
      clearColor $= Color4 0 0 0 1

keyboardMouseHandler :: State -> KeyboardMouseCallback
keyboardMouseHandler _ (Char 'q') Down _ _ = exitWith ExitSuccess
keyboardMouseHandler s (Char ' ') Down _ _ = run s $~ not
keyboardMouseHandler s (Char 'a') Down _ _ = env s $~ update
keyboardMouseHandler s (SpecialKey KeyLeft) Down _ _ = env s $~ moveGoal (-1,0)
keyboardMouseHandler s (SpecialKey KeyRight) Down _ _ = env s $~ moveGoal (1,0)
keyboardMouseHandler s (SpecialKey KeyUp) Down _ _ = env s $~ moveGoal (0,1)
keyboardMouseHandler s (SpecialKey KeyDown) Down _ _ = env s $~ moveGoal (0,-1)
keyboardMouseHandler s (MouseButton LeftButton) Down _ p = env s $~ (flipObstacle (convertCoords p))
keyboardMouseHandler s (MouseButton RightButton) Down _ p = env s $~ (flipPursuer (convertCoords p))
keyboardMouseHandler _ _ _ _ _ = return ()

convertCoords :: Position -> (Int,Int)
convertCoords (Position x y) = (fromIntegral (x `div` truncate sqSize),
                                gridSize - fromIntegral (y `div` truncate sqSize))

main :: IO ()
main = do
  _ <- getArgsAndInitialize
  initialDisplayMode $= [ DoubleBuffered, RGBAMode ]
  initialWindowSize $= Size 512 512
  initialWindowPosition $= Position 0 0
  _ <- createWindow "Agent Visualization"

  state <- makeState

  displayCallback $= displayFunc state
  reshapeCallback $= Just reshapeFunc
  keyboardMouseCallback $= Just (keyboardMouseHandler state)

  addTimerCallback tick (timerFunc state)

  mainLoop