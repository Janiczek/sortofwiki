port module Ports exposing (colorThemeFromJs, colorThemeToJs)

import Json.Encode


port colorThemeToJs : Json.Encode.Value -> Cmd msg


port colorThemeFromJs : (Json.Encode.Value -> msg) -> Sub msg
