module UI exposing
    ( TableCellVerticalAlign(..)
    , TableHeaderCell
    , TableWidth(..)
    , appHeaderBarClass
    , appHeaderDividerClass
    , appHeaderH1Class
    , appHeaderPrimaryLinkClass
    , appHeaderPrimaryPlainClass
    , appHeaderSecondaryAfterDividerClass
    , appHeaderSecondaryBracketClass
    , appHeaderSecondaryMetaClass
    , appHeaderSecondaryWikiLabelEmClass
    , appHeaderSecondaryWikiWrapClass
    , appHeaderTitleRowClass
    , appMainScrollRegionId
    , appRootClass
    , backlinksListClass
    , backlinksSectionClass
    , button
    , dangerButton
    , formTextInputClass
    , formTextareaClass
    , formTextareaCompactClass
    , hostAdminWikiDetailCardClass
    , hostAdminWikiDetailDangerCardClass
    , hostAdminWikiDetailGridClass
    , hostAdminWikiDetailMainStackClass
    , hostAdminWikiDetailPageTitleClass
    , hostAdminWikiDetailShellClass
    , hostAdminWikiDetailSideStackClass
    , hostAdminWikiSlugClass
    , hostAdminWikiStatusBadgeActiveClass
    , hostAdminWikiStatusBadgeInactiveClass
    , layoutHolyGrailClass
    , layoutLeftNavAsideClass
    , layoutMainColumnClass
    , layoutMainColumnClassAuditFill
    , markdownBlockQuoteClass
    , markdownCodeBlockCodeClass
    , markdownCodeBlockPreClass
    , markdownCodeSpanClass
    , markdownContainerClass
    , markdownHeading1Class
    , markdownHeading2Class
    , markdownHeading3Class
    , markdownHeading4Class
    , markdownHeading5Class
    , markdownHeading6Class
    , markdownLinkClass
    , markdownListItemClass
    , markdownOrderedListClass
    , markdownParagraphClass
    , markdownTextareaClass
    , markdownThematicBreakClass
    , markdownUnorderedListClass
    , markdownWikiLinkMissingClass
    , sideNavListClass
    , sideNavNavClass
    , sideNavPublicAdminLinkClass
    , sideNavStackClass
    , sidebarContainerClass
    , sidebarDesktopOnlyClass
    , sidebarHeading
    , sidebarLink
    , sidebarNavSectionBodyClass
    , table
    , tableCellClass
    , tableHeaderText
    , tableTd
    , themeToggleButtonClass
    , togglableChip
    , trStriped
    , wikiCatalogCardClass
    , wikiCatalogCardSlugEmClass
    , wikiCatalogCardSummaryClass
    , wikiCatalogCardTitleClass
    , wikiCatalogCardTitleLinkClass
    , wikiCatalogGridClass
    )

import Html exposing (Attribute, Html)
import Html.Attributes as Attr
import Html.Events as Events
import TW


{-| `Html.main_` in the app shell: overflow-y scroll region for article content. Used for in-page fragment scrolling (window scroll is not used; see `Frontend` Dom tasks).
-}
appMainScrollRegionId : String
appMainScrollRegionId =
    "app-main-scroll"


appRootClass : String
appRootClass =
    "app-root flex flex-col h-dvh max-h-dvh min-h-0 overflow-hidden px-[0.5rem] pt-[0.25rem] pb-0 font-serif bg-[var(--bg)] text-[var(--fg)] leading-[1.35] [&_a]:text-[var(--link)] [&_a]:underline [&_a]:underline-offset-[2px] [&_a:hover]:text-[var(--link-hover)] [&_a:focus-visible]:outline-2 [&_a:focus-visible]:outline-[var(--focus-ring)] [&_a:focus-visible]:outline-offset-2 [&_button:focus-visible]:outline-2 [&_button:focus-visible]:outline-[var(--focus-ring)] [&_button:focus-visible]:outline-offset-2 [&_input:focus-visible]:outline-2 [&_input:focus-visible]:outline-[var(--focus-ring)] [&_input:focus-visible]:outline-offset-2 [&_textarea:focus-visible]:outline-2 [&_textarea:focus-visible]:outline-[var(--focus-ring)] [&_textarea:focus-visible]:outline-offset-2 [&_h1]:mt-[0.35rem] [&_h1]:mb-[0.2rem] [&_h1]:font-semibold [&_h1]:leading-[1.2] [&_h2]:mt-[0.35rem] [&_h2]:mb-[0.2rem] [&_h2]:font-semibold [&_h2]:leading-[1.2] [&_h2]:text-[1.1rem] [&_h3]:mt-[0.35rem] [&_h3]:mb-[0.2rem] [&_h3]:font-semibold [&_h3]:leading-[1.2] [&_h3]:text-[1rem] [&_p]:my-[0.25rem] [&_label]:block [&_label]:mt-[0.25rem] [&_label]:text-[1rem] [&_label]:text-[var(--fg-muted)]"


{-| Single-line controls (`type=text`, `password`, …). Omit on `checkbox` / `radio`.
-}
formTextInputClass : String
formTextInputClass =
    "font-inherit text-[1rem] px-[0.3rem] py-[0.15rem] mt-[0.1rem] mb-[0.2rem] border border-[var(--border)] bg-[var(--input-bg)] text-[var(--fg)] max-w-full box-border"


{-| Border, spacing, and width shared by `formTextareaClass` and `markdownBodyTextareaClass`.
-}
formTextareaChromeClass : String
formTextareaChromeClass =
    "box-border px-[0.3rem] py-[0.15rem] mt-[0.1rem] mb-[0.2rem] border border-[var(--border)] bg-[var(--input-bg)] text-[var(--fg)] max-w-full w-full max-w-[48rem]"


{-| Serif body typography plus `formTextareaChromeClass`.
-}
formTextareaShellClass : String
formTextareaShellClass =
    "font-inherit text-[1rem] " ++ formTextareaChromeClass


{-| Default tall multi-line control.
-}
formTextareaClass : String
formTextareaClass =
    formTextareaShellClass ++ " min-h-[5rem]"


{-| Short textarea inside flex layouts (e.g. review decision notes).
-}
formTextareaCompactClass : String
formTextareaCompactClass =
    formTextareaShellClass ++ " min-h-0"


buttonClass : String
buttonClass =
    "[font-family:inherit] text-[1rem] px-[0.45rem] py-[0.2rem] mt-[0.1rem] mr-[0.15rem] mb-[0.1rem] ml-0 bg-[var(--btn-bg)] text-[var(--btn-fg)] border border-[var(--btn-border)] rounded-[3px] cursor-pointer hover:brightness-[1.08] dark:hover:brightness-[1.12] dark:hover:border-[var(--border-dash)] disabled:opacity-[0.55] disabled:cursor-not-allowed"


{-| Filled destructive control. Uses `--danger-btn-bg` / `--danger-btn-fg` (not `--danger`) so class-based `.dark` matches CSS variables; see `head.html`.
-}
buttonDangerClass : String
buttonDangerClass =
    "[font-family:inherit] text-[1rem] px-[0.45rem] py-[0.2rem] mt-[0.1rem] mr-[0.15rem] mb-[0.1rem] ml-0 bg-[var(--danger-btn-bg)] text-[var(--danger-btn-fg)] border border-[var(--danger-btn-bg)] rounded-[3px] cursor-pointer hover:brightness-[1.12] disabled:opacity-[0.55] disabled:cursor-not-allowed"


button : List (Attribute msg) -> List (Html msg) -> Html msg
button attrs children =
    Html.button (TW.cls buttonClass :: attrs) children


dangerButton : List (Attribute msg) -> List (Html msg) -> Html msg
dangerButton attrs children =
    Html.button (TW.cls buttonDangerClass :: attrs) children


{-| Badge-style toggle (e.g. filter chips). Inactive = muted surface; active = green chip tokens in `head.html`.
-}
togglableChip : List (Attribute msg) -> { pressed : Bool, onClick : msg, label : String } -> Html msg
togglableChip extraAttrs { pressed, onClick, label } =
    let
        stateClass : String
        stateClass =
            if pressed then
                "bg-[var(--chip-on-bg)] text-[var(--chip-on-fg)] border-[var(--chip-on-border)] shadow-[inset_0_1px_0_rgba(255,255,255,0.12)]"

            else
                "bg-[var(--chip-off-bg)] text-[var(--chip-off-fg)] border-[var(--chip-off-border)] hover:bg-[var(--chrome-bg)]"
    in
    Html.button
        (TW.cls
            ("[font-family:inherit] inline-flex items-center rounded-md text-[0.8125rem] leading-snug px-[0.55rem] py-[0.28rem] border font-medium "
                ++ "transition-[background-color,border-color,color] duration-100 cursor-pointer "
                ++ "focus-visible:outline focus-visible:outline-2 focus-visible:outline-[var(--focus-ring)] focus-visible:outline-offset-2 "
                ++ stateClass
            )
            :: Attr.type_ "button"
            :: Attr.attribute "aria-pressed"
                (if pressed then
                    "true"

                 else
                    "false"
                )
            :: Events.onClick onClick
            :: extraAttrs
        )
        [ Html.text label ]


sidebarContainerClass : String
sidebarContainerClass =
    "min-h-0 self-stretch overflow-y-auto overscroll-contain flex flex-col gap-y-[0.9rem] leading-[1.35] text-[var(--fg-muted)] bg-transparent border-0 text-[1rem] py-[0.85rem] pl-[0.85rem] pr-0 font-serif max-[56rem]:px-0"


sidebarHeadingClass : String
sidebarHeadingClass =
    "m-0 mb-[0.35rem] text-[0.82rem] font-semibold tracking-[0.04em] text-[var(--fg-muted)]"


sidebarHeading : String -> Html msg
sidebarHeading label =
    Html.h2 [ TW.cls sidebarHeadingClass ] [ Html.text label ]


{-| Indents block content under `sidebarHeading` (same inset as the first ToC heading tier in `PageToc`).
-}
sidebarNavSectionBodyClass : String
sidebarNavSectionBodyClass =
    "pl-[0.35rem]"


sidebarLinkClass : String
sidebarLinkClass =
    "text-[var(--link)] hover:text-[var(--link-hover)] underline underline-offset-[2px]"


sidebarLink : List (Attribute msg) -> List (Html msg) -> Html msg
sidebarLink attrs children =
    Html.a (TW.cls sidebarLinkClass :: attrs) children


tableBaseClass : String
tableBaseClass =
    "border-collapse text-[1rem] border border-[var(--border)]"


tableAutoClass : String
tableAutoClass =
    "w-auto " ++ tableBaseClass


tableFullWidthMax72Class : String
tableFullWidthMax72Class =
    "w-full max-w-[72rem] " ++ tableBaseClass


tableFullWidthClass : String
tableFullWidthClass =
    "w-full " ++ tableBaseClass


tableHeaderCellClass : String
tableHeaderCellClass =
    "px-[0.35rem] py-[0.15rem] border border-[var(--border)] text-left align-top bg-[var(--chrome-bg)] font-semibold border-b border-[var(--border)]"


{-| Same as `tableHeaderCellClass` but vertically centers content (e.g. rows with buttons). Use `tableHeaderCellClass` when cell text may wrap across lines.
-}
tableHeaderCellMiddleClass : String
tableHeaderCellMiddleClass =
    "px-[0.35rem] py-[0.15rem] border border-[var(--border)] text-left align-middle bg-[var(--chrome-bg)] font-semibold border-b border-[var(--border)]"


tableCellClass : String
tableCellClass =
    "px-[0.35rem] py-[0.15rem] border border-[var(--border)] text-left align-top"


{-| Same as `tableCellClass` but vertically centers content. Use `tableCellClass` when multi-line cell text is expected.
-}
tableCellMiddleClass : String
tableCellMiddleClass =
    "px-[0.35rem] py-[0.15rem] border border-[var(--border)] text-left align-middle"


tableStripedRowClass : String
tableStripedRowClass =
    "even:bg-[var(--table-stripe)]"


{-| Fixed layout presets for `table` (width / max-width on the `table` element).
-}
type TableWidth
    = TableAuto
    | TableFullMax72
    | TableFull


{-| Chooses top- vs middle-aligned table cell classes for `table` header cells and for `tableTd`.
-}
type TableCellVerticalAlign
    = TableAlignTop
    | TableAlignMiddle


{-| One column heading: optional extra `th` attributes plus cell contents.
-}
type alias TableHeaderCell msg =
    { extraAttrs : List (Attribute msg)
    , children : List (Html msg)
    }


{-| Shorthand header cell with only a text label.
-}
tableHeaderText : String -> TableHeaderCell msg
tableHeaderText label =
    { extraAttrs = []
    , children = [ Html.text label ]
    }


tableWidthClass : TableWidth -> String
tableWidthClass width =
    case width of
        TableAuto ->
            tableAutoClass

        TableFullMax72 ->
            tableFullWidthMax72Class

        TableFull ->
            tableFullWidthClass


headerClassForVerticalAlign : TableCellVerticalAlign -> String
headerClassForVerticalAlign align =
    case align of
        TableAlignTop ->
            tableHeaderCellClass

        TableAlignMiddle ->
            tableHeaderCellMiddleClass


cellClassForVerticalAlign : TableCellVerticalAlign -> String
cellClassForVerticalAlign align =
    case align of
        TableAlignTop ->
            tableCellClass

        TableAlignMiddle ->
            tableCellMiddleClass


{-| App themed `table` with a single header row and styled `th` cells. Pass body rows as `Html.tr` (see `trStriped` and `tableTd`).
-}
table :
    TableWidth
    -> List (Attribute msg)
    ->
        { theadAttrs : List (Attribute msg)
        , headerRowAttrs : List (Attribute msg)
        , headerAlign : TableCellVerticalAlign
        , headers : List (TableHeaderCell msg)
        , tbodyAttrs : List (Attribute msg)
        , rows : List (Html msg)
        }
    -> Html msg
table width tableExtraAttrs config =
    Html.table
        (TW.cls (tableWidthClass width) :: tableExtraAttrs)
        [ Html.thead config.theadAttrs
            [ Html.tr config.headerRowAttrs
                (List.map
                    (\h ->
                        Html.th
                            (TW.cls (headerClassForVerticalAlign config.headerAlign) :: h.extraAttrs)
                            h.children
                    )
                    config.headers
                )
            ]
        , Html.tbody config.tbodyAttrs config.rows
        ]


{-| Striped data row (`even:` background). Merge with your own `tr` attributes.
-}
trStriped : List (Attribute msg) -> List (Html msg) -> Html msg
trStriped attrs children =
    Html.tr (TW.cls tableStripedRowClass :: attrs) children


{-| Styled `td` for use inside `table` body rows. Avoid a second `TW.cls` in `extraAttrs` (duplicate `class`); merge utilities into `tableCellClass` / `tableCellMiddleClass` on a raw `Html.td` instead.
-}
tableTd : TableCellVerticalAlign -> List (Attribute msg) -> List (Html msg) -> Html msg
tableTd align extraAttrs children =
    Html.td (TW.cls (cellClassForVerticalAlign align) :: extraAttrs) children


appHeaderSecondaryMetaClass : String
appHeaderSecondaryMetaClass =
    "text-[var(--fg-muted)] font-normal max-w-full"


appHeaderSecondaryAfterDividerClass : String
appHeaderSecondaryAfterDividerClass =
    "italic min-w-0"


appHeaderSecondaryBracketClass : String
appHeaderSecondaryBracketClass =
    "not-italic text-[var(--fg-muted)] opacity-[0.42] font-normal text-[0.88em]"


appHeaderSecondaryWikiWrapClass : String
appHeaderSecondaryWikiWrapClass =
    appHeaderSecondaryMetaClass
        ++ " inline-flex items-baseline flex-wrap gap-x-[0.15rem] gap-y-[0.05rem]"


appHeaderSecondaryWikiLabelEmClass : String
appHeaderSecondaryWikiLabelEmClass =
    "text-[var(--fg-muted)] font-normal"


appHeaderPrimaryLinkClass : String
appHeaderPrimaryLinkClass =
    "font-semibold text-[var(--fg)] no-underline"


appHeaderPrimaryPlainClass : String
appHeaderPrimaryPlainClass =
    "font-semibold"


appHeaderTitleRowClass : String
appHeaderTitleRowClass =
    "inline-flex items-center flex-wrap gap-x-[0.65rem] gap-y-[0.35rem] max-w-full"


appHeaderDividerClass : String
appHeaderDividerClass =
    "self-stretch w-0 my-0 border-l-2 border-[var(--border)] min-h-[1.15em]"


appHeaderBarClass : String
appHeaderBarClass =
    "shrink-0 flex flex-row flex-wrap items-center justify-between gap-y-[0.5rem] gap-x-[0.75rem] -mx-[0.5rem] px-[0.5rem] pt-[0.2rem] pb-[0.5rem] border-b border-dashed border-[var(--border-dash)]"


appHeaderH1Class : String
appHeaderH1Class =
    "m-0 text-[1.35rem] font-semibold leading-[1.2] text-[var(--fg)] flex-1 min-w-0 font-serif"


themeToggleButtonClass : String
themeToggleButtonClass =
    "shrink-0 inline-flex items-center justify-center w-[2.35rem] h-[2.35rem] p-0 m-0 border-0 rounded-none bg-transparent text-[var(--fg)] cursor-pointer hover:bg-[var(--chrome-bg)]"


sideNavNavClass : String
sideNavNavClass =
    "w-full"


sideNavStackClass : String
sideNavStackClass =
    "flex flex-col gap-y-[0.9rem] w-full text-[var(--fg-muted)] text-[1rem] font-serif leading-[1.35]"


sideNavListClass : String
sideNavListClass =
    "list-none m-0 p-0 flex flex-col gap-[0.35rem] items-start"


{-| Overrides app-root link color for the public `/admin` entry (host login), so it reads as secondary nav.
-}
sideNavPublicAdminLinkClass : String
sideNavPublicAdminLinkClass =
    "!text-[var(--fg-muted)] hover:!text-[var(--link)]"


wikiCatalogGridClass : String
wikiCatalogGridClass =
    "grid w-full max-w-[72rem] grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3"


hostAdminWikiDetailShellClass : String
hostAdminWikiDetailShellClass =
    "w-full min-w-0"


hostAdminWikiDetailGridClass : String
hostAdminWikiDetailGridClass =
    "grid grid-cols-1 gap-3.5 lg:grid-cols-[minmax(0,1fr)_17rem] lg:gap-5 lg:items-start"


hostAdminWikiDetailMainStackClass : String
hostAdminWikiDetailMainStackClass =
    "flex flex-col gap-3 min-w-0"


hostAdminWikiDetailSideStackClass : String
hostAdminWikiDetailSideStackClass =
    "flex flex-col gap-3 min-w-0"


hostAdminWikiDetailCardClass : String
hostAdminWikiDetailCardClass =
    "rounded border border-[var(--border)] bg-[var(--chrome-bg)] p-3 shadow-[0_1px_2px_rgba(0,0,0,0.04)]"


hostAdminWikiDetailDangerCardClass : String
hostAdminWikiDetailDangerCardClass =
    "rounded border border-[var(--danger)] bg-[var(--danger-bg)] p-3 shadow-[0_1px_2px_rgba(0,0,0,0.06)]"


hostAdminWikiDetailPageTitleClass : String
hostAdminWikiDetailPageTitleClass =
    "m-0 text-[1.35rem] font-semibold leading-[1.2] text-[var(--fg)]"


hostAdminWikiSlugClass : String
hostAdminWikiSlugClass =
    "[font-family:var(--font-mono)] text-[0.95rem] text-[var(--fg-muted)] break-all"


hostAdminWikiStatusBadgeActiveClass : String
hostAdminWikiStatusBadgeActiveClass =
    "inline-block text-[0.82rem] font-semibold tracking-wide uppercase px-[0.4rem] py-[0.12rem] rounded border border-[var(--border)] bg-[var(--input-bg)] text-[var(--fg)]"


hostAdminWikiStatusBadgeInactiveClass : String
hostAdminWikiStatusBadgeInactiveClass =
    "inline-block text-[0.82rem] font-semibold tracking-wide uppercase px-[0.4rem] py-[0.12rem] rounded border border-[var(--border-dash)] bg-[var(--bg)] text-[var(--fg-muted)]"


wikiCatalogCardClass : String
wikiCatalogCardClass =
    "rounded border border-[var(--border)] bg-[var(--chrome-bg)] p-3 font-serif"


wikiCatalogCardTitleClass : String
wikiCatalogCardTitleClass =
    "m-0 text-[1.1rem] font-semibold"


wikiCatalogCardTitleLinkClass : String
wikiCatalogCardTitleLinkClass =
    "no-underline hover:underline underline-offset-[0.2em]"


wikiCatalogCardSlugEmClass : String
wikiCatalogCardSlugEmClass =
    "text-[0.9rem] font-normal opacity-80"


wikiCatalogCardSummaryClass : String
wikiCatalogCardSummaryClass =
    "m-0 mt-2 min-h-[1.25rem]"


markdownContainerClass : String
markdownContainerClass =
    "block max-w-[52rem] text-[0.95rem] font-serif"


markdownHeading1Class : String
markdownHeading1Class =
    "mt-[1rem] mb-[0.25rem] font-semibold text-[var(--fg)] text-[1.3rem]"


markdownHeading2Class : String
markdownHeading2Class =
    "mt-[1rem] mb-[0.25rem] font-semibold text-[var(--fg)] text-[1.12rem]"


markdownHeading3Class : String
markdownHeading3Class =
    "mt-[1rem] mb-[0.25rem] font-semibold text-[var(--fg)] text-[1.02rem]"


markdownHeading4Class : String
markdownHeading4Class =
    "mt-[1rem] mb-[0.25rem] font-semibold text-[var(--fg)] text-[0.98rem]"


markdownHeading5Class : String
markdownHeading5Class =
    "mt-[1rem] mb-[0.25rem] font-semibold text-[var(--fg)] text-[0.98rem]"


markdownHeading6Class : String
markdownHeading6Class =
    "mt-[1rem] mb-[0.25rem] font-semibold text-[var(--fg)] text-[0.98rem]"


markdownParagraphClass : String
markdownParagraphClass =
    "my-[0.35rem]"


markdownBlockQuoteClass : String
markdownBlockQuoteClass =
    "my-[0.35rem] px-[0.5rem] py-[0.2rem] border-l-[3px] border-l-[var(--border)] text-[var(--fg-muted)]"


markdownLinkClass : String
markdownLinkClass =
    "text-[var(--link)] hover:text-[var(--link-hover)] underline underline-offset-[2px]"


markdownWikiLinkMissingClass : String
markdownWikiLinkMissingClass =
    "!text-red-600 dark:!text-red-400 hover:!text-red-700 dark:hover:!text-red-300 underline underline-offset-[2px]"


markdownUnorderedListClass : String
markdownUnorderedListClass =
    "my-[0.25rem] pl-[1.35rem] list-disc"


markdownOrderedListClass : String
markdownOrderedListClass =
    "my-[0.25rem] pl-[1.35rem] list-decimal"


markdownListItemClass : String
markdownListItemClass =
    "my-[0.1rem]"


markdownCodeSpanClass : String
markdownCodeSpanClass =
    "[font-family:var(--font-mono)] text-[0.88em] bg-[var(--code-bg)] px-[0.2rem] py-[0.05rem]"


markdownCodeBlockPreClass : String
markdownCodeBlockPreClass =
    "[font-family:var(--font-mono)] my-[0.35rem] px-[0.45rem] py-[0.35rem] overflow-x-auto bg-[var(--code-bg)] border border-[var(--border)] text-[0.85rem] leading-[1.4]"


markdownCodeBlockCodeClass : String
markdownCodeBlockCodeClass =
    "[font-family:var(--font-mono)] border-0 p-0 bg-transparent"


{-| Markdown source `textarea` typography: matches fenced code blocks (`markdownCodeBlockPreClass`).
-}
markdownTextareaClass : String
markdownTextareaClass =
    "[font-family:var(--font-mono)] text-[0.85rem] leading-[1.4]"


markdownThematicBreakClass : String
markdownThematicBreakClass =
    "my-[0.35rem] border-0 border-t border-[var(--border)]"


backlinksSectionClass : String
backlinksSectionClass =
    "max-w-[52rem]"


backlinksListClass : String
backlinksListClass =
    "list-none m-0 p-0 flex flex-col gap-[0.25rem]"


sidebarDesktopOnlyClass : String
sidebarDesktopOnlyClass =
    "max-[56rem]:hidden"


layoutLeftNavAsideClass : String
layoutLeftNavAsideClass =
    "self-stretch min-h-0 overflow-y-auto overscroll-contain leading-[1.35] text-[var(--fg)] text-[1rem] border-r border-dashed border-[var(--border-dash)] py-[0.85rem] pr-[0.85rem] pl-0 max-[56rem]:border-r-0 max-[56rem]:px-0"


layoutHolyGrailClass : Bool -> String
layoutHolyGrailClass hasRightColumn =
    if hasRightColumn then
        "grid min-h-0 min-w-0 h-full w-full flex-1 overflow-hidden items-stretch gap-y-[0.65rem] px-[0.5rem] -mx-[0.5rem] max-w-none grid-rows-[minmax(0,1fr)] auto-rows-[minmax(0,1fr)] grid-cols-[minmax(11rem,16rem)_minmax(0,1fr)_minmax(10rem,14rem)] max-[56rem]:grid-cols-1"

    else
        "grid min-h-0 min-w-0 h-full w-full flex-1 overflow-hidden items-stretch gap-y-[0.65rem] px-[0.5rem] -mx-[0.5rem] max-w-none grid-rows-[minmax(0,1fr)] auto-rows-[minmax(0,1fr)] grid-cols-[minmax(11rem,16rem)_minmax(0,1fr)] max-[56rem]:grid-cols-1"


layoutMainColumnClass : Bool -> String
layoutMainColumnClass hasRightColumn =
    if hasRightColumn then
        "min-h-0 min-w-0 overflow-y-auto overscroll-contain px-[0.85rem] py-[0.85rem] border-r border-dashed border-[var(--border-dash)] max-[56rem]:border-r-0 max-[56rem]:px-0"

    else
        "min-h-0 min-w-0 overflow-y-auto overscroll-contain py-[0.85rem] pl-[0.85rem] pr-0 border-r-0 max-[56rem]:px-0"


{-| Main column when the route owns internal scrolling (audit log: filters fixed, table scrolls). Replaces outer `overflow-y-auto` with `overflow-hidden flex flex-col`.
-}
layoutMainColumnClassAuditFill : Bool -> String
layoutMainColumnClassAuditFill hasRightColumn =
    if hasRightColumn then
        "min-h-0 min-w-0 flex flex-col overflow-hidden overscroll-contain px-[0.85rem] py-[0.85rem] border-r border-dashed border-[var(--border-dash)] max-[56rem]:border-r-0 max-[56rem]:px-0"

    else
        "min-h-0 min-w-0 flex flex-col overflow-hidden overscroll-contain py-[0.85rem] pl-[0.85rem] pr-0 border-r-0 max-[56rem]:px-0"
