module UI.FocusVisible exposing (on)

import Html exposing (Attribute)
import TW


{-| Shared `focus-visible` ring for buttons, links, inputs, textareas.
-}
class : String
class =
    "focus-visible:outline-2 focus-visible:outline-[var(--focus-ring)] focus-visible:outline-offset-2"


on : List (Attribute msg) -> List (Attribute msg)
on attrs =
    TW.cls class :: attrs
