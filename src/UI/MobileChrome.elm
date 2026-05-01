module UI.MobileChrome exposing (menuButton)

import Html exposing (Attribute, Html)
import Html.Attributes as Attr
import TW


{-| Hamburger control for opening the mobile wiki nav drawer. Visible only below Tailwind `md`.
-}
menuButton : List (Attribute msg) -> Html msg
menuButton attrs =
    Html.button
        (TW.cls "md:hidden inline-flex h-11 min-w-[2.75rem] shrink-0 items-center justify-center rounded-md border border-[var(--border-subtle)] bg-[var(--chrome-bg)] text-[1.15rem] leading-none text-[var(--fg)] shadow-sm hover:bg-[var(--chrome-bg-hover)]"
            :: Attr.type_ "button"
            :: Attr.attribute "aria-controls" "mobile-side-nav-drawer"
            :: attrs
        )
        [ Html.span [ Attr.attribute "aria-hidden" "true" ] [ Html.text "☰" ]
        ]
