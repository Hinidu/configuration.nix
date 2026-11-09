{-# LANGUAGE UnicodeSyntax #-}

import XMonad
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.SetWMName
import XMonad.Hooks.StatusBar
import XMonad.Hooks.StatusBar.PP
import XMonad.Hooks.UrgencyHook
import XMonad.Layout.Grid
import XMonad.Layout.NoBorders (smartBorders)
import XMonad.Layout.PerWorkspace (onWorkspace)
import XMonad.Util.EZConfig (additionalKeys, additionalKeysP)

import Graphics.X11.ExtraTypes.XF86

-- NixOS compiles this file into the xmonad binary, so there's nothing to
-- recompile at runtime: launch skips the recompilation logic of `xmonad`.
main = getDirectories >>= launch myConfig

myConfig = withSB xmobar'
    . withUrgencyHookC NoUrgencyHook urgentConfig
    . docks
    $ def
    { terminal          = terminal'
    , workspaces        = workspaces'
    , layoutHook        = layoutHook'
    , startupHook       = startupHook'
    , manageHook        = manageHook' <+> manageHook def
    , modMask           = modMask'
    , focusFollowsMouse = False
    }
    `additionalKeys` keys'
    `additionalKeysP` keysP'

modMask' = mod4Mask

terminal' = "urxvt"

workspaces' = ["im", "web", "term", "dev", "unity", "read", "video", "mus", "unknown"]

-- xmobar reads its config from ~/.config/xmobar/xmobarrc (Home Manager) and
-- gets workspaces from the _XMONAD_LOG property (the XMonadLog plugin)
xmobar' = statusBarProp "xmobar" (pure xmobarPP')

xmobarPP' = xmobarPP
    { ppCurrent = xmobarBorder "Bottom" "#859900" 4 . xmobarColor "#859900" ""
    , ppUrgent  = xmobarColor "#dc322f" "" . wrap "[" "]" . xmobarStrip
    , ppTitle   = const ""
    , ppSep     = xmobarColor "#268bd2" "" " <+> "
    }

urgentConfig = UrgencyConfig { suppressWhen = Focused, remindWhen = Dont }

layoutHook' = smartBorders $ avoidStruts
    $ onWorkspace "im" (Full ||| Grid)
    $ onWorkspace "web" (Full ||| Grid)
    $ onWorkspace "term" (Grid ||| Full)
    $ onWorkspace "dev" Full
    $ layoutHook def

-- Java GUI apps (JetBrains IDEs and the like) draw grey windows in
-- non-reparenting window managers unless they think they run in LG3D
startupHook' = setWMName "LG3D"

manageHook' = composeAll
    [ className =? "slack"                --> doShift "im"
    , className =? "google-chrome-stable" --> doShift "web"
    , className =? "Unity"                --> doShift "unity"
    , title =? "zathura"                  --> doShift "read"
    , className =? "Gxmessage"            --> doFloat
    , className =? "Kodi"                 --> doFloat
    , className =? "mpv"                  --> doFloat
    , title =? "xmessage"                 --> doFloat
    , title =? "Starting Unity..."        --> doFloat
    , title =? "Hold on..."               --> doFloat
    ]

-- scrot doesn't create the target directory itself. The delay lets the key be
-- released first, otherwise scrot can't grab the pointer to select an area.
screenshot scrotArgs = spawn $
    "mkdir -p ~/screenshots && sleep 0.2 && scrot " ++ scrotArgs
    ++ " ~/screenshots/%Y-%m-%d-%H%M%S_\\$wx\\$h.png"

-- The touchpad is found by name: xinput ids change between boots and kernels
touchpad enable = spawn $
    "xinput " ++ (if enable then "enable" else "disable")
    ++ " \"$(xinput list --name-only | grep -i touchpad | head -n 1)\""

keys' =
    [ ((modMask' .|. shiftMask, xK_space), spawn $ terminal' ++ " -e fish -i -c vifm")
    -- The binary comes from PATH, so after nixos-rebuild switch this restarts
    -- into the new config (the default binding calls `xmonad --restart`,
    -- which only works for configs compiled from ~/.xmonad)
    , ((modMask', xK_q), restart "xmonad" True)
    , ((modMask' .|. shiftMask, xK_t), sendMessage ToggleStruts)
    , ((0, xK_Print), screenshot "")
    , ((controlMask, xK_Print), screenshot "--select")
    , ((modMask', xK_Print), screenshot "--focused --border")
    , ((0, xF86XK_MonBrightnessDown), spawn "brightnessctl set 10%-")
    , ((0, xF86XK_MonBrightnessUp), spawn "brightnessctl set +10%")
    , ((0, xF86XK_AudioLowerVolume), spawn "pamixer -d 5")
    , ((0, xF86XK_AudioRaiseVolume), spawn "pamixer -i 5")
    , ((0, xF86XK_AudioMute), spawn "pamixer -t")
    , ((modMask', xK_m), touchpad True)
    , ((modMask' .|. shiftMask, xK_m), touchpad False)
    ]

keysP' =
    [ ("M-x c", spawn "google-chrome-stable")
    , ("M-x x", spawn "google-chrome-stable --incognito")
    , ("M-x v", spawn $ terminal' ++ " -e nvim")
    , ("M-x u", spawn "unityhub-3k")
    , ("M-x s", spawn "slack")
    , ("M-x p", spawn "zathura")
    ]
