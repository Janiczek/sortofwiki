module UI.WikiPageRightRailMobile exposing (toggleRailButton)

import Html exposing (Html)
import Html.Attributes as Attr
import Html.Events as Events
import TW


{-| Mobile-only control to expand/collapse the wiki published-page right rail (bottom panel on small viewports). Chevron placement follows the edit page "Published" row (`translate-y` / `rotate-90`).
-}
toggleRailButton : { expanded : Bool, onToggle : msg } -> Html msg
toggleRailButton { expanded, onToggle } =
    let
        chevronClass : String
        chevronClass =
            "absolute right-0 inline-block text-[1rem] leading-none select-none scale-[1.5]"
                ++ (if expanded then
                        " top-[2px] rotate-90 translate-y-[-1px]"

                    else
                        " top-[2px] translate-y-[-3px] translate-x-[-1px]"
                   )
    in
    Html.button
        [ Attr.type_ "button"
        , TW.cls
            "w-full md:hidden appearance-none border-0 border-b border-[var(--border-subtle)] bg-transparent m-0 px-4 py-1 text-left leading-[1] cursor-pointer transition-colors hover:bg-[var(--chrome-bg-hover)] hover:text-[var(--fg)]"
        , Events.onClick onToggle
        , Attr.attribute "aria-expanded"
            (if expanded then
                "true"

             else
                "false"
            )
        ]
        [ Html.span [ TW.cls "relative inline-flex items-center text-[0.8125rem] font-semibold leading-tight text-[var(--fg-muted)]" ]
            [ Html.span [ TW.cls "pr-4" ]
                [ Html.text "Metadata" ]
            , Html.span
                [ TW.cls chevronClass
                , Attr.attribute "aria-hidden" "true"
                ]
                [ Html.text "▸" ]
            ]
        ]

