module Evergreen.V29.ColorTheme exposing (..)


type ColorTheme
    = Light
    | Dark


type ColorThemePreference
    = FollowSystem
    | Fixed ColorTheme


type Incoming
    = Sync ColorThemePreference ColorTheme
    | System ColorTheme
