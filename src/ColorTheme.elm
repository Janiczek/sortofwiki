module ColorTheme exposing (ColorTheme(..), toggle)

{-| UI color mode (light spreadsheet theme vs dark green theme).
-}


type ColorTheme
    = Light
    | Dark


toggle : ColorTheme -> ColorTheme
toggle theme =
    case theme of
        Light ->
            Dark

        Dark ->
            Light
