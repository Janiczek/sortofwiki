module UI.FormActionFooter exposing (Align(..), sticky)

import Html as H exposing (Html)
import Html.Attributes as Attr


type Align
    = AlignEnd
    | AlignBetween


stickyBaseClass : String
stickyBaseClass =
    "shrink-0 sticky bottom-0 z-10 border-t border-[var(--border-subtle)] bg-[var(--bg)] px-4 py-3 flex"


{-| Sticky bottom action bar for editor shells.
-}
sticky : { align : Align, left : List (Html msg), right : List (Html msg) } -> Html msg
sticky cfg =
    let
        rowClass : String
        rowClass =
            case cfg.align of
                AlignEnd ->
                    stickyBaseClass ++ " justify-end gap-2"

                AlignBetween ->
                    stickyBaseClass ++ " justify-between items-center gap-2"

        children : List (Html msg)
        children =
            case cfg.align of
                AlignEnd ->
                    cfg.right

                AlignBetween ->
                    cfg.left ++ cfg.right
    in
    H.footer [ Attr.class rowClass ] children
