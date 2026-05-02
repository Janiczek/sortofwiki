module UI.MobileChrome exposing (menuButton)

import Html exposing (Attribute, Html)
import Html.Attributes as Attr
import TW


{-| Hamburger control for opening the mobile wiki nav drawer. Visible only below Tailwind `md`.
-}
menuButton : List (Attribute msg) -> Html msg
menuButton attrs =
    Html.button
        (TW.cls "md:hidden inline-flex h-9 min-w-9 shrink-0 items-center justify-center rounded-md border border-[var(--border-subtle)] bg-[var(--chrome-bg)] px-1.5 text-base leading-none text-[var(--fg)] shadow-sm hover:bg-[var(--chrome-bg-hover)] active:bg-[color-mix(in_srgb,var(--chrome-bg-hover)_78%,black_22%)] active:shadow-inner"
            :: Attr.type_ "button"
            :: Attr.attribute "aria-controls" "mobile-side-nav-drawer"
            :: attrs
        )
        [ Html.span
            [ TW.cls "-translate-y-0.5 inline-flex leading-none"
            , Attr.attribute "aria-hidden" "true"
            ]
            [ Html.text "☰" ]
        ]
