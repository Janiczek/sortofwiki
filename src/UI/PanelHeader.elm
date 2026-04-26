module UI.PanelHeader exposing (Kind(..), view)

import Html as H exposing (Html)
import Html.Attributes as Attr
import UI.Heading


rowClass : String
rowClass =
    "shrink-0 px-4 py-2 border-b border-[var(--border-subtle)]"


{-| Panel title row shell (border-b, horizontal padding).
-}
row : Html msg -> Html msg
row child =
    H.div [ Attr.class rowClass ] [ child ]


type Kind
    = Primary
    | Secondary


{-| Pane section header row for primary/secondary heading variants.
-}
view : { kind : Kind, text : String } -> Html msg
view cfg =
    case cfg.kind of
        Primary ->
            row (UI.Heading.panelHeadingPrimary [] [ H.text cfg.text ])

        Secondary ->
            row (UI.Heading.panelHeadingSecondary [] [ H.text cfg.text ])
