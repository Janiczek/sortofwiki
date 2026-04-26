module UI.IconInput exposing (view)

import Html as H exposing (Attribute, Html)
import Html.Attributes as Attr


{-| Text input with a decorative leading icon (login / search-style row).

`attrs` should include `id`, `type_`, `value`, input handlers, and styling such as `UI.formTextInputAttr`. Wrapper adds `relative` shell, icon positioning, and `pl-9` on the input.

-}
view :
    { icon : Html msg
    , attrs : List (Attribute msg)
    }
    -> Html msg
view cfg =
    H.div [ Attr.class "relative" ]
        [ H.span
            [ Attr.class "absolute left-3 top-1/2 -translate-y-1/2 text-[var(--fg-muted)]"
            , Attr.attribute "aria-hidden" "true"
            ]
            [ cfg.icon ]
        , H.input
            (Attr.class "w-full pl-9" :: cfg.attrs)
            []
        ]
