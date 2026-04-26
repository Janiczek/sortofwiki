module UI.AsyncState exposing (empty, loading)

import Html as H exposing (Html)
import TW
import UI.EmptyState


{-| Standard loading line (paragraph body only; wrap in `Html.div` with `id` when tests need it).
-}
loading : String -> Html msg
loading message =
    H.p [ TW.cls contentParagraphClass ] [ H.text message ]


{-| Semantic empty block with status role (delegates to `UI.EmptyState.status`).
-}
empty : { id : String, text : String } -> Html msg
empty =
    UI.EmptyState.status


contentParagraphClass : String
contentParagraphClass =
    "my-[1rem] leading-[1.6] [font-family:var(--font-serif)] first:mt-0"
