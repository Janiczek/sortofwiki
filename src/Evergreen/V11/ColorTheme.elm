module Evergreen.V11.ColorTheme exposing (..)


type ColorTheme
    = Light
    | Dark


type ColorThemePreference
    = FollowSystem
    | Fixed ColorTheme


type Incoming
    = Sync ColorThemePreference ColorTheme
    | System ColorTheme
