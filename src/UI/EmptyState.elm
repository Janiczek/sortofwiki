module UI.EmptyState exposing (paragraph, status)

import Html as H exposing (Html)
import Html.Attributes as Attr
import TW


{-| Empty copy as a single `UI.contentParagraph` with `id` (no outer wrapper).
-}
paragraph : { id : String, text : String } -> Html msg
paragraph cfg =
    contentParagraph [ Attr.id cfg.id ] [ H.text cfg.text ]


{-| Status region with `role="status"` wrapping paragraph copy (catalog-style).
-}
status : { id : String, text : String } -> Html msg
status cfg =
    H.div
        [ Attr.id cfg.id
        , Attr.attribute "role" "status"
        ]
        [ contentParagraph [] [ H.text cfg.text ] ]


contentParagraph : List (H.Attribute msg) -> List (Html msg) -> Html msg
contentParagraph attrs children =
    H.p (TW.cls contentParagraphClass :: attrs) children


contentParagraphClass : String
contentParagraphClass =
    "my-[1rem] leading-[1.6] [font-family:var(--font-serif)] first:mt-0"
