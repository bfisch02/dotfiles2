import System.IO (hPutStrLn, Handle)
import XMonad
import XMonad.Hooks.DynamicLog
import XMonad.Hooks.ManageDocks
import XMonad.Layout.IndependentScreens
import qualified XMonad.StackSet as W
import XMonad.Util.EZConfig (additionalKeys)
import XMonad.Util.Run (spawnPipe)

import Control.Applicative
import Graphics.X11.Xinerama (getScreenInfo)
import Graphics.X11.Xlib.Display (closeDisplay)

myTerminal = "gnome-terminal"
myModMask = mod4Mask

-- Program names that should not be managed and tiled
composeHook = composeAll [
        className =? "Gimp" --> doFloat
    ]

myManageHook = manageDocks <+> composeHook <+> manageHook defaultConfig
myLayoutHook = avoidStruts $ layoutHook defaultConfig
myLogHook xmproc = dynamicLogWithPP xmobarPP {
                            ppOutput = hPutStrLn xmproc,
                            ppTitle = xmobarColor "green" "" . shorten 50
                        }

restartCmd :: String
restartCmd = "if type xmonad; then xmonad --recompile && \
              \xmonad --restart; else xmessage xmonad not in PATH; fi"

-- Get all Xinerama Screen #'s
getScreens :: IO [Int]
getScreens = openDisplay "" >>= liftA2 (<*) f closeDisplay
    where f = fmap (zipWith const [0..]) . getScreenInfo

-- Relationship between physical placement of monitor and screen number in Xinerama
xOrder = [2, 1, 5,
          3, 0, 4]

-- xmobar on every screen
xmobarScreen :: Int -> IO Handle
xmobarScreen = spawnPipe . ("xmobar -x " ++) . show

--------------------------------------------------------------------------------
main = do
    xmproc <- spawnPipe "xmobar"
    screens <- getScreens
    _ <- spawn myTerminal
    let myWorkspaces = map show screens
    xmonad $ defaultConfig
        { terminal = myTerminal
        , modMask = myModMask
        , XMonad.workspaces = myWorkspaces
        , manageHook = myManageHook
        , layoutHook = myLayoutHook
        , logHook = myLogHook xmproc
        } `additionalKeys` (
        [ ((mod4Mask, xK_Return), spawn myTerminal)
        , ((controlMask .|. shiftMask, xK_l), spawn "slock")
        , ((mod4Mask, xK_q), spawn restartCmd)
        ]

        ++
        -- mod-{w,e,r,s,d,f} %! Switch focus to physical/Xinerama screens
        -- mod-shift-{w,e,r,s,d,f} %! Throw client to physical/Xinerama screen
        [ ((m .|. mod4Mask, key), screenWorkspace sc >>= flip whenJust (windows . f))
          | (key, sc) <- zip [xK_w, xK_e, xK_r, xK_s, xK_d, xK_f] xOrder
          , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]
        ]

        ++
        -- mod-[1..6] %! Switch focus to workspace N (TODO: of this screen)
        -- mod-shift-[1..6] %! Move client to workspace N (TODO: of this screen)
        [ ((m .|. mod4Mask, k), windows $ f i)
        | (i, k) <- zip myWorkspaces [xK_1 .. xK_9]
        , (f, m) <- [(W.view, 0), (W.shift, shiftMask)]
        ]
        )

