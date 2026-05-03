module Evergreen.V28.ColorTheme exposing (..)


type ColorTheme
    = Light
    | Dark


type ColorThemePreference
    = FollowSystem
    | Fixed ColorTheme


type Incoming
    = Sync ColorThemePreference ColorTheme
    | System ColorTheme
