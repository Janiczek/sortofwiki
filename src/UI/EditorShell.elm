module UI.EditorShell exposing (view)

import Html exposing (Attribute, Html)
import TW


{-| Outer card for submit-new / submit-edit markdown editor (`Frontend` wiki flows).
-}
containerClass : String
containerClass =
    "flex flex-col h-full min-h-0 w-full overflow-hidden"


{-| Top field row (slug, tags, …) inside editor chrome.
-}
controlsRowClass : String
controlsRowClass =
    "shrink-0 px-4 py-3 border-b border-[var(--border-subtle)] bg-[var(--bg)] flex flex-wrap gap-3 items-end"


{-| Two-column editor + preview grid below the toolbar.
-}
contentGridClass : String
contentGridClass =
    "grid min-h-0 flex-1 w-full grid-cols-2 divide-x divide-[var(--border-subtle)]"


view :
    { containerAttrs : List (Attribute msg)
    , controlsAttrs : List (Attribute msg)
    , controlsChildren : List (Html msg)
    , contentAttrs : List (Attribute msg)
    , contentChildren : List (Html msg)
    }
    -> Html msg
view cfg =
    Html.div
        (TW.cls containerClass :: cfg.containerAttrs)
        [ if List.isEmpty cfg.controlsChildren then
            Html.text ""

          else
            Html.div
                (TW.cls controlsRowClass :: cfg.controlsAttrs)
                cfg.controlsChildren
        , Html.div
            (TW.cls contentGridClass :: cfg.contentAttrs)
            cfg.contentChildren
        ]
