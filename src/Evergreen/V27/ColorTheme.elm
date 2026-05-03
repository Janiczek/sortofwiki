module Evergreen.V27.ColorTheme exposing (..)


type ColorTheme
    = Light
    | Dark


type ColorThemePreference
    = FollowSystem
    | Fixed ColorTheme


type Incoming
    = Sync ColorThemePreference ColorTheme
    | System ColorTheme
