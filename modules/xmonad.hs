{-# LANGUAGE UnicodeSyntax #-}

import XMonad
import XMonad.Actions.DynamicProjects
import XMonad.Hooks.ManageDocks
import XMonad.Hooks.SetWMName
import XMonad.Hooks.StatusBar
import XMonad.Hooks.StatusBar.PP
import XMonad.Hooks.UrgencyHook
import XMonad.Layout.Grid
import XMonad.Layout.NoBorders (smartBorders)
import XMonad.Layout.PerWorkspace (onWorkspaces)
import XMonad.Prompt
import XMonad.Util.EZConfig (additionalKeys, additionalKeysP)
import XMonad.Util.Run (runProcessWithInput)
import qualified XMonad.StackSet as W
import Data.List (isPrefixOf)
import Data.Maybe (isJust)
import Text.Read (readMaybe)

import Graphics.X11.ExtraTypes.XF86

-- NixOS compiles this file into the xmonad binary, so there's nothing to
-- recompile at runtime: launch skips the recompilation logic of `xmonad`.
main = getDirectories >>= launch myConfig

myConfig = withSB (xmobar' <> xmobarAgents)
    . withUrgencyHookC NoUrgencyHook urgentConfig
    . docks
    . dynamicProjects projects'
    $ def
    { terminal          = terminal'
    , workspaces        = workspaces'
    , logHook           = removeAbandonedWorkspaces
    , layoutHook        = layoutHook'
    , startupHook       = startupHook'
    , manageHook        = manageHook' <+> manageHook def
    , modMask           = modMask'
    , focusFollowsMouse = False
    }
    `additionalKeys` keys'
    `additionalKeysP` keysP'

modMask' = mod4Mask

terminal' = "kitty"

-- desktop.projects of the host (modules/projects.nix), M-1… in this order.
-- Switching to a project's workspace makes its directory xmonad's own, so a
-- terminal opened there starts in it.
projects' =
    @projects@

workspaces' = map projectName projects'

-- M-g makes workspaces on the fly that aren't in the list (e.g. "mac" for the
-- VNC viewer); DynamicProjects doesn't remove them, so a left one that has no
-- windows goes away here. The bar is updated after this hook, so it never
-- shows such a workspace.
removeAbandonedWorkspaces = modify $ \xstate ->
    let windowSet = windowset xstate
        isKept workspace = W.tag workspace `elem` workspaces' || isJust (W.stack workspace)
    in xstate { windowset = windowSet { W.hidden = filter isKept (W.hidden windowSet) } }

-- M-g / M-S-g: switch to or send the window to a project by name, Tab
-- completes, a new name makes a new workspace; ` cycles through the other
-- modes (send, rename, change the project's directory). Over the main bar,
-- with its height and font.
projectPrompt' = def
    { font              = "xft:FiraCode Nerd Font:size=@promptFont@"
    , bgColor           = "@backgroundHighlight@"
    , fgColor           = "@emphasis@"
    , bgHLight          = "@green@"
    , fgHLight          = "@background@"
    , promptBorderWidth = 0
    , position          = Top
    , height            = @promptHeight@
    }

-- xmobar reads its config from ~/.config/xmobar/xmobarrc (Home Manager) and
-- gets workspaces from the _XMONAD_LOG property (the XMonadLog plugin)
xmobar' = statusBarProp "xmobar" (pure xmobarPP')

-- Second line below the main bar: Claude Code background sessions. It gets
-- nothing from xmonad, so it only needs to be started and stopped with it
xmobarAgents = statusBarGeneric "xmobar ~/.config/xmobar/agents.xmobarrc" mempty

xmobarPP' = xmobarPP
    -- The underline width is put in by modules/xserver.nix from the screen's dpi
    { ppCurrent = xmobarBorder "Bottom" "#859900" @underlineWidth@ . xmobarColor "#859900" ""
    , ppUrgent  = xmobarColor "#dc322f" "" . wrap "[" "]" . xmobarStrip
    , ppTitle   = const ""
    , ppSep     = xmobarColor "#268bd2" "" " <+> "
    }

urgentConfig = UrgencyConfig { suppressWhen = Focused, remindWhen = Dont }

-- Project workspaces are mostly a handful of terminals, so a grid comes first
layoutHook' = smartBorders $ avoidStruts
    $ onWorkspaces ["im", "web"] (Full ||| Grid)
    $ Grid ||| Full ||| layoutHook def

-- Java GUI apps (JetBrains IDEs and the like) draw grey windows in
-- non-reparenting window managers unless they think they run in LG3D
startupHook' = do
    setWMName "LG3D"
    -- Claude Code sessions side panel (conky); doesn't start a second copy
    -- on restart
    spawn "agents-panel start"

manageHook' = composeAll
    [ className =? "slack"                --> doShift "im"
    , className =? "google-chrome-stable" --> doShift "web"
    , className =? "Unity"                --> doShift "work"
    -- A window whose instance name is "workspace-<name>" goes to that
    -- workspace: agents-focus-window opens a session's kitty with the name of
    -- the session's project (kitty --name)
    , fmap (workspacePrefix `isPrefixOf`) appName
                                          --> (appName >>= doShift . drop (length workspacePrefix))
    , className =? "Gxmessage"            --> doFloat
    , className =? "Kodi"                 --> doFloat
    , className =? "mpv"                  --> doFloat
    , title =? "xmessage"                 --> doFloat
    , title =? "Starting Unity..."        --> doFloat
    , title =? "Hold on..."               --> doFloat
    ]

workspacePrefix = "workspace-"

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
    -- Jump to the window that asked for attention, e.g. a Claude Code session
    -- waiting for input (its Notification hook sets the urgency hint on the
    -- terminal's $WINDOWID with xdotool)
    , ((modMask', xK_u), focusUrgent)
    -- Show or hide the Claude Code sessions side panel
    , ((modMask', xK_a), spawn "agents-panel toggle")
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

-- Jump to the window of the Claude Code session with this number on the agents
-- panel and bar, like M-u does for the urgent one. agents-focus-window finds
-- it by title and prints "window <id>"; a session that isn't open anywhere it
-- opens in a new kitty, and if the session belongs to a project, prints
-- "workspace <name>" to go there (the manageHook puts the window on it). It
-- tells about a missing session itself and prints nothing then.
focusAgent number = do
    output <- runProcessWithInput "agents-focus-window" [show number] ""
    case words output of
        [] -> return ()
        ["window", windowId] | Just window <- readMaybe windowId -> windows (W.focusWindow window)
        ["workspace", name] | name `elem` workspaces' -> windows (W.view name)
        _ -> error ("agents-focus-window printed something unexpected: " ++ show output)

keysP' =
    [ ("M-s " ++ show number, focusAgent number) | number <- [1 .. 9 :: Int] ] ++
    [ ("M-g", switchProjectPrompt projectPrompt')
    , ("M-S-g", shiftToProjectPrompt projectPrompt')
    , ("M-x c", spawn "google-chrome-stable")
    , ("M-x x", spawn "google-chrome-stable --incognito")
    , ("M-x v", spawn $ terminal' ++ " -e nvim")
    , ("M-x u", spawn "unityhub-scaled")
    , ("M-x s", spawn "slack")
    , ("M-x p", spawn "zathura")
    ]
