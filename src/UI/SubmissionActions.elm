module UI.SubmissionActions exposing (primaryPairButtons, primaryPairRow)

import Html as H exposing (Attribute, Html)
import Html.Attributes as Attr
import UI.Button


{-| Canonical "Save draft" + primary submit pair used in submission flows.

`submitLabel` is typically "Submit for review", "Create", or "Save" depending on trust mode.

-}
primaryPairButtons :
    { saveDraftAttrs : List (Attribute msg)
    , submitAttrs : List (Attribute msg)
    , submitLabel : String
    }
    -> List (Html msg)
primaryPairButtons cfg =
    [ UI.Button.secondaryButton cfg.saveDraftAttrs [ H.text "Save draft" ]
    , UI.Button.button cfg.submitAttrs [ H.text cfg.submitLabel ]
    ]


{-| Same buttons wrapped in a flex row (`justify-end gap-2`), for footers that need a nested row (submit-edit pattern).
-}
primaryPairRow :
    { saveDraftAttrs : List (Attribute msg)
    , submitAttrs : List (Attribute msg)
    , submitLabel : String
    }
    -> Html msg
primaryPairRow cfg =
    H.div [ Attr.class "flex justify-end gap-2" ]
        (primaryPairButtons cfg)
