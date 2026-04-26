module UI.Heading exposing
    ( cardHeadingDanger
    , cardHeadingLg
    , cardHeadingSm
    , contentHeading2
    , gridHeadingCol1
    , gridHeadingCol2
    , gridHeadingPrimaryCol1
    , gridHeadingSecondaryCol2
    , markdownHeading1
    , markdownHeading2
    , markdownHeading3
    , markdownHeading4
    , markdownHeading5
    , markdownHeading6
    , panelHeadingPrimary
    , panelHeadingSecondary
    , sidebarHeading
    )

import Html exposing (Attribute, Html)
import TW


{-| Matches letter-spacing on sidebar section titles (`sidebarHeading`); reuse for ToC lines and markdown headings.
-}
sidebarSubheadingTrackingClass : String
sidebarSubheadingTrackingClass =
    "tracking-[0.04em]"


sidebarHeadingClass : String
sidebarHeadingClass =
    "m-0 mb-[0.35rem] text-[0.82rem] [font-family:var(--font-ui)] font-semibold "
        ++ sidebarSubheadingTrackingClass
        ++ " text-[var(--fg-muted)]"


sidebarHeading : String -> Html msg
sidebarHeading label =
    Html.h2 [ TW.cls sidebarHeadingClass ] [ Html.text label ]


contentHeading2Class : String
contentHeading2Class =
    "[font-family:var(--font-serif)] mt-[0.5rem] mb-[0.25rem] font-semibold leading-[1.3] text-[1.25rem]"


contentHeading2 : List (Attribute msg) -> List (Html msg) -> Html msg
contentHeading2 attrs children =
    Html.h2 (TW.cls contentHeading2Class :: attrs) children


markdownHeading1Class : String
markdownHeading1Class =
    "mt-[1.5rem] mb-[0.5rem] font-semibold leading-[1.2] first:mt-0 "
        ++ sidebarSubheadingTrackingClass
        ++ " text-[var(--fg)] text-[2.5rem]"


markdownHeading2Class : String
markdownHeading2Class =
    "mt-[1.25rem] mb-[0.4rem] font-semibold leading-[1.3] first:mt-0 "
        ++ sidebarSubheadingTrackingClass
        ++ " text-[var(--fg)] text-[2rem]"


markdownHeading3Class : String
markdownHeading3Class =
    "mt-[1rem] mb-[0.35rem] font-semibold leading-[1.35] first:mt-0 "
        ++ sidebarSubheadingTrackingClass
        ++ " text-[var(--fg)] text-[1.5rem]"


markdownHeading4Class : String
markdownHeading4Class =
    "mt-[0.75rem] mb-[0.25rem] font-semibold leading-[1.35] first:mt-0 "
        ++ sidebarSubheadingTrackingClass
        ++ " text-[var(--fg)] text-[1.25rem]"


markdownHeading5Class : String
markdownHeading5Class =
    "mt-[0.75rem] mb-[0.25rem] font-semibold leading-[1.35] first:mt-0 "
        ++ sidebarSubheadingTrackingClass
        ++ " text-[var(--fg)] text-[1.125rem]"


markdownHeading6Class : String
markdownHeading6Class =
    "mt-[0.75rem] mb-[0.25rem] font-semibold leading-[1.35] first:mt-0 "
        ++ sidebarSubheadingTrackingClass
        ++ " text-[var(--fg)] text-[1.0625rem]"


panelHeadingPrimaryClass : String
panelHeadingPrimaryClass =
    "m-0 !mt-0 !mb-0 shrink-0 text-sm font-semibold leading-tight text-[var(--fg)]"


panelHeadingSecondaryClass : String
panelHeadingSecondaryClass =
    "m-0 !mt-0 !mb-0 shrink-0 text-sm font-semibold leading-tight text-[var(--fg-muted)]"


reviewDiffCellHeadingClass : String
reviewDiffCellHeadingClass =
    "m-0 !mt-0 !mb-0 shrink-0 text-sm font-semibold leading-tight text-[var(--fg)]"


panelHeadingPrimary : List (Attribute msg) -> List (Html msg) -> Html msg
panelHeadingPrimary attrs children =
    Html.h3 (TW.cls panelHeadingPrimaryClass :: attrs) children


panelHeadingSecondary : List (Attribute msg) -> List (Html msg) -> Html msg
panelHeadingSecondary attrs children =
    Html.h3 (TW.cls panelHeadingSecondaryClass :: attrs) children


gridHeadingPrimaryCol1 : List (Attribute msg) -> List (Html msg) -> Html msg
gridHeadingPrimaryCol1 attrs children =
    Html.h3
        (TW.cls "m-0 !mt-0 !mb-0 shrink-0 text-sm font-semibold leading-tight text-[var(--fg)] col-start-1 row-start-1" :: attrs)
        children


gridHeadingSecondaryCol2 : List (Attribute msg) -> List (Html msg) -> Html msg
gridHeadingSecondaryCol2 attrs children =
    Html.h3
        (TW.cls "m-0 !mt-0 !mb-0 shrink-0 text-sm font-semibold leading-tight text-[var(--fg-muted)] col-start-2 row-start-1" :: attrs)
        children


gridHeadingCol1 : List (Attribute msg) -> List (Html msg) -> Html msg
gridHeadingCol1 attrs children =
    Html.h3 (TW.cls (reviewDiffCellHeadingClass ++ " col-start-1 row-start-1") :: attrs) children


gridHeadingCol2 : List (Attribute msg) -> List (Html msg) -> Html msg
gridHeadingCol2 attrs children =
    Html.h3 (TW.cls (reviewDiffCellHeadingClass ++ " col-start-2 row-start-1") :: attrs) children


cardHeadingLg : List (Attribute msg) -> List (Html msg) -> Html msg
cardHeadingLg attrs children =
    Html.h2 (TW.cls "m-0 mb-2 text-[1.1rem] font-semibold text-[var(--fg)] leading-[1.2]" :: attrs) children


cardHeadingSm : List (Attribute msg) -> List (Html msg) -> Html msg
cardHeadingSm attrs children =
    Html.h2 (TW.cls "m-0 mb-2 text-[0.8125rem] font-semibold text-[var(--fg)] leading-[1.2]" :: attrs) children


cardHeadingDanger : List (Attribute msg) -> List (Html msg) -> Html msg
cardHeadingDanger attrs children =
    Html.h3 (TW.cls "m-0 mb-1.5 text-[0.8125rem] font-semibold text-[var(--danger)] leading-[1.2]" :: attrs) children


markdownHeading1 : List (Attribute msg) -> List (Html msg) -> Html msg
markdownHeading1 attrs children =
    Html.h1 (TW.cls markdownHeading1Class :: attrs) children


markdownHeading2 : List (Attribute msg) -> List (Html msg) -> Html msg
markdownHeading2 attrs children =
    Html.h2 (TW.cls markdownHeading2Class :: attrs) children


markdownHeading3 : List (Attribute msg) -> List (Html msg) -> Html msg
markdownHeading3 attrs children =
    Html.h3 (TW.cls markdownHeading3Class :: attrs) children


markdownHeading4 : List (Attribute msg) -> List (Html msg) -> Html msg
markdownHeading4 attrs children =
    Html.h4 (TW.cls markdownHeading4Class :: attrs) children


markdownHeading5 : List (Attribute msg) -> List (Html msg) -> Html msg
markdownHeading5 attrs children =
    Html.h5 (TW.cls markdownHeading5Class :: attrs) children


markdownHeading6 : List (Attribute msg) -> List (Html msg) -> Html msg
markdownHeading6 attrs children =
    Html.h6 (TW.cls markdownHeading6Class :: attrs) children
