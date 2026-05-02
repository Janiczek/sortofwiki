module UI.Link exposing
    ( breakAllSpan
    , contentLink
    , listItemTight
    , missingLink
    , outsideHttpAttrs
    , navListItem
    , navListItemMuted
    , navPrimary
    , sidebarLink
    , subtleLink
    )

import Html exposing (Attribute, Html)
import Html.Attributes as Attr
import MarkdownLinkTarget
import TW
import UI.FocusVisible
import Url exposing (Url)


{-| `href` plus `target`/`rel` when `href` resolves to another HTTP(S) origin than `currentUrl`.
Use for hardcoded anchors and compose into `contentLink` / raw `Html.a` attribute lists.
-}
outsideHttpAttrs : Url -> String -> List (Attribute msg)
outsideHttpAttrs currentUrl href =
    Attr.href href :: MarkdownLinkTarget.attrsIfOutsideHttp currentUrl href


contentLinkClass : String
contentLinkClass =
    "[font-family:var(--font-serif)] text-[var(--link)] hover:text-[var(--link-hover)] hover:bg-[var(--link-bg-hover)] underline underline-offset-[2px]"


contentLink : List (Attribute msg) -> List (Html msg) -> Html msg
contentLink attrs children =
    Html.a (UI.FocusVisible.on (TW.cls contentLinkClass :: attrs)) children


sidebarLinkClass : String
sidebarLinkClass =
    "block w-full rounded py-[0.14rem] px-[0.55rem] -ml-[0.55rem] [font-family:var(--font-ui)] text-[0.8125rem] text-[var(--link)] hover:text-[var(--link-hover)] hover:bg-[var(--link-bg-hover)] underline underline-offset-[2px]"


sidebarLink : List (Attribute msg) -> List (Html msg) -> Html msg
sidebarLink attrs children =
    Html.a (TW.cls sidebarLinkClass :: attrs) children


navPrimaryClass : String
navPrimaryClass =
    "font-semibold text-[var(--fg)] hover:bg-[var(--link-bg-hover)] underline underline-offset-[2px]"


{-| Block-level nav item link: no underline, hover background, full-width rounded.
-}
navListItemClass : Bool -> String
navListItemClass emphasized =
    "block w-full rounded py-[0.14rem] px-[0.55rem] -ml-[0.55rem] text-[var(--link)] hover:text-[var(--link-hover)] hover:bg-[var(--link-bg-hover)] underline underline-offset-[2px]"
        ++ (if emphasized then
                " font-bold"

            else
                ""
           )


{-| Overrides app-root link color for the public `/admin` entry (host login), so it reads as secondary nav.
-}
navListItemMutedClass : String
navListItemMutedClass =
    "block w-full rounded py-[0.14rem] px-[0.55rem] -ml-[0.55rem] !text-[var(--fg-muted)] hover:!text-[var(--link)] hover:bg-[var(--link-bg-hover)] underline underline-offset-[2px]"


missingClass : String
missingClass =
    "!text-red-700 dark:!text-red-400 hover:!bg-[var(--danger-link-bg-hover)] underline underline-offset-[2px]"


navListItemMuted : Bool -> List (Attribute msg) -> List (Html msg) -> Html msg
navListItemMuted emphasized attrs children =
    Html.a
        (UI.FocusVisible.on
            (TW.cls
                (navListItemMutedClass
                    ++ (if emphasized then
                            " font-bold"

                        else
                            ""
                       )
                )
                :: attrs
            )
        )
        children


navListItem : Bool -> List (Attribute msg) -> List (Html msg) -> Html msg
navListItem emphasized attrs children =
    Html.a (UI.FocusVisible.on (TW.cls (navListItemClass emphasized) :: attrs)) children


navPrimary : List (Attribute msg) -> List (Html msg) -> Html msg
navPrimary attrs children =
    Html.a (UI.FocusVisible.on (TW.cls navPrimaryClass :: attrs)) children


missingLink : List (Attribute msg) -> List (Html msg) -> Html msg
missingLink attrs children =
    Html.a (TW.cls missingClass :: attrs) children


subtleLink : List (Attribute msg) -> List (Html msg) -> Html msg
subtleLink attrs children =
    Html.a (TW.cls "text-[var(--link)] text-[0.8125rem] underline underline-offset-2" :: attrs) children


listItemTight : List (Attribute msg) -> List (Html msg) -> Html msg
listItemTight attrs children =
    Html.li (TW.cls "m-0 leading-[1.3]" :: attrs) children


breakAllSpan : List (Attribute msg) -> List (Html msg) -> Html msg
breakAllSpan attrs children =
    Html.span (TW.cls "break-all" :: attrs) children
