module UI.StatusBadge exposing (view)

import Html exposing (Html)
import TW


activeClass : String
activeClass =
    "inline-block text-[0.82rem] font-semibold tracking-wide uppercase px-[0.4rem] py-[0.12rem] border border-[var(--border)] bg-[var(--input-bg)] text-[var(--fg)]"


inactiveClass : String
inactiveClass =
    "inline-block text-[0.82rem] font-semibold tracking-wide uppercase px-[0.4rem] py-[0.12rem] border border-[var(--border-dash)] bg-[var(--bg)] text-[var(--fg-muted)]"


view : { isActive : Bool, text : String } -> Html msg
view config =
    Html.span
        [ TW.cls
            (if config.isActive then
                activeClass

             else
                inactiveClass
            )
        ]
        [ Html.text config.text ]
