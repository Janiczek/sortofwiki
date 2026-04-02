module TW exposing (cls, mod)

import Html exposing (Attribute)
import Html.Attributes as Attr


{-| Tailwind utility classes as a single HTML `class` attribute.
-}
cls : String -> Attribute msg
cls utilities =
    Attr.class utilities


{-| Prefix each whitespace-separated utility with a variant (for example `hover`, `md`).

`TW.mod "hover" "bg-blue-400 text-sm"` sets `class="hover:bg-blue-400 hover:text-sm"`.

-}
mod : String -> String -> Attribute msg
mod variant utilities =
    utilities
        |> String.words
        |> List.filter (\w -> w /= "")
        |> List.map (\u -> variant ++ ":" ++ u)
        |> String.join " "
        |> Attr.class
