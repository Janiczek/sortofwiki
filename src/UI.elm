module UI exposing
    ( TableCellVerticalAlign(..)
    , TableHeaderCell
    , TableWidth(..)
    , appHeaderBarAttr
    , appHeaderBarClass
    , appHeaderDividerAttr
    , appHeaderDividerClass
    , appHeaderH1Attr
    , appHeaderH1Class
    , appHeaderPrimaryPlainAttr
    , appHeaderPrimaryPlainClass
    , appHeaderSecondaryAfterDividerAttr
    , appHeaderSecondaryAfterDividerClass
    , appHeaderSecondaryBracketAttr
    , appHeaderSecondaryBracketClass
    , appHeaderSecondaryMetaAttr
    , appHeaderSecondaryMetaClass
    , appHeaderSecondaryWikiLabelEmAttr
    , appHeaderSecondaryWikiLabelEmClass
    , appHeaderSecondaryWikiWrapAttr
    , appHeaderSecondaryWikiWrapClass
    , appHeaderTitleRowAttr
    , appHeaderTitleRowClass
    , appMainScrollRegionId
    , appRootClass
    , appRootClassAttr
    , auditFilterLegendTextAttr
    , auditFilterTypeGroupAttr
    , auditLogCol
    , auditLogColGroup
    , auditLogHeaderRow
    , auditLogTableView
    , auditMainColumnBodyInnerAttr
    , auditTableBaseClass
    , auditTableBodyTableClass
    , auditTableHeaderCellClass
    , auditTableHeaderTableClass
    , backlinksListAttr
    , backlinksListClass
    , backlinksSectionAttr
    , backlinksSectionClass
    , cellClassForVerticalAlign
    , classAttr
    , clusterAttr
    , contentLabel
    , contentLabelClass
    , contentParagraph
    , contentParagraphClass
    , flexColMin0Gap3Attr
    , flexRowMin0Attr
    , flexWrapGap1Attr
    , flexWrapGap2Attr
    , flexWrapGap2Mt3Attr
    , formCenteredCardAttr
    , formCenteredCardClass
    , formFeedbackRowAttr
    , formFeedbackTextSmAttr
    , formFieldLabelBlockAttr
    , formFieldMinW0Attr
    , formStackMb3Attr
    , formTextInputAttr
    , formTextInputAuditFilterAttr
    , formTextInputAuditFilterClass
    , formTextInputClass
    , formTextInputHostAdminSlugAttr
    , formTextInputHostAdminSlugClass
    , gridCellCol2Row2Attr
    , gridCellStackCol1Row3Attr
    , gridCellStackCol2Row3Attr
    , gridTwoByTwoDiffStrAttr
    , gridTwoColEditorStrAttr
    , headerClassForVerticalAlign
    , holyGrailLayout
    , hostAdminAuditDiffPageShellAttr
    , hostAdminAuditFiltersCardAttr
    , hostAdminAuditFiltersGridAttr
    , hostAdminAuditPageShellAttr
    , hostAdminBackupCardAttr
    , hostAdminCardParagraphTightAttr
    , hostAdminDangerBlurbAttr
    , hostAdminDeleteFormStackAttr
    , hostAdminStatusParaAttr
    , hostAdminWikiDetailCardAttr
    , hostAdminWikiDetailCardClass
    , hostAdminWikiDetailDangerCardAttr
    , hostAdminWikiDetailDangerCardClass
    , hostAdminWikiDetailFormStackAttr
    , hostAdminWikiDetailGridAttr
    , hostAdminWikiDetailGridClass
    , hostAdminWikiDetailMainStackAttr
    , hostAdminWikiDetailMainStackClass
    , hostAdminWikiDetailPageTitleAttr
    , hostAdminWikiDetailPageTitleClass
    , hostAdminWikiDetailShellAttr
    , hostAdminWikiDetailShellClass
    , hostAdminWikiDetailSideStackAttr
    , hostAdminWikiDetailSideStackClass
    , hostAdminWikiListSlugAttr
    , hostAdminWikiSlugClass
    , inputTextAttr
    , inputTextFullAttr
    , layoutHolyGrailAttr
    , layoutHolyGrailClass
    , layoutLeftNavAsideAttr
    , layoutLeftNavAsideClass
    , layoutMainColumnClass
    , layoutMainColumnClassAuditFill
    , layoutMainColumnForRouteAttr
    , mainContentPaddingAttr
    , markdownBlockQuoteAttr
    , markdownBlockQuoteClass
    , markdownCodeBlockCodeAttr
    , markdownCodeBlockCodeClass
    , markdownCodeBlockPreAttr
    , markdownCodeBlockPreClass
    , markdownCodeSpanAttr
    , markdownCodeSpanClass
    , markdownContainerAttr
    , markdownContainerClass
    , markdownListItemAttr
    , markdownListItemClass
    , markdownOrderedListAttr
    , markdownOrderedListClass
    , markdownParagraphAttr
    , markdownParagraphClass
    , markdownPreviewScrollClass
    , markdownPreviewScrollMinFlexAttr
    , markdownPreviewScrollMinFlexFullHeightAttr
    , markdownTableAttr
    , markdownTableCellAttr
    , markdownTableCellClass
    , markdownTableClass
    , markdownTableHeaderCellAttr
    , markdownTableHeaderCellClass
    , markdownTableRowAttr
    , markdownTableRowClass
    , markdownThematicBreakAttr
    , markdownThematicBreakClass
    , markdownTodoAttr
    , markdownTodoClass
    , markdownUnorderedListAttr
    , markdownUnorderedListClass
    , mb2Attr
    , mb3Attr
    , minW0Attr
    , mobileOnlySideNavAsideAttrs
    , mobileSideNavAsideAttrs
    , mobileSideNavDrawerId
    , mobileWikiNavBackdropView
    , mt3Mb3Attr
    , newPageEditorMarkdownPreviewCellAttr
    , newPageEditorMarkdownPreviewCellClass
    , pageActionsSidebarStackAttr
    , pageActionsTopBorderBlockAttr
    , reviewDeletePagePreviewTitleAttr
    , reviewDiffNewPagePreviewColShellAttr
    , reviewFieldsetAttr
    , reviewLegendAttr
    , reviewNestedNoteColumnAttr
    , reviewOptionLabelStrongAttr
    , reviewRadioColumnAttr
    , reviewRadioRowAttr
    , rightRailSectionCards
    , sideNavBottomSectionAttr
    , sideNavBottomSectionClass
    , sideNavListAttr
    , sideNavListClass
    , sideNavMainSectionAttr
    , sideNavMainSectionClass
    , sideNavNavAttr
    , sideNavNavClass
    , sideNavStackAttr
    , sideNavStackClass
    , sidebarContainerAttr
    , sidebarContainerClass
    , sidebarDesktopOnlyAttr
    , sidebarDesktopOnlyClass
    , sidebarM0Attr
    , sidebarNavHorizontalIndentAttr
    , sidebarNavSectionBodyAttr
    , sidebarNavSectionBodyClass
    , sidebarNavSectionBodyStackAttr
    , sidebarTocListIndentAttr
    , sidebarTocListRootAttr
    , stackAttr
    , stackTightAttr
    , submissionGridTight2ColAttr
    , submissionStatusDangerLineAttr
    , submitActionsBarAttr
    , submitSummaryParagraphAttr
    , surfaceCardAttr
    , table
    , tableAutoClass
    , tableBaseClass
    , tableCellClass
    , tableCellMiddleClass
    , tableCellMonoTimestampAttr
    , tableCellMonoTimestampClass
    , tableFullWidthMax72Class
    , tableHeaderCellClass
    , tableHeaderCellMiddleClass
    , tableHeaderText
    , tableStripedRowClass
    , tableTd
    , tableTdSerif
    , tableWidthClass
    , tagPillAttr
    , tagPillClass
    , tagPillsListAttr
    , todosListDiscAttr
    , trStriped
    , viewDiffKindInlineAttr
    , wikiAdminAuditFiltersGridAttr
    , wikiAdminAuditPageShellAttr
    , wikiCatalogCardAttr
    , wikiCatalogCardClass
    , wikiCatalogCardSlugEmAttr
    , wikiCatalogCardSlugEmClass
    , wikiCatalogCardSummaryAttr
    , wikiCatalogCardSummaryClass
    , wikiCatalogCardTitleAttr
    , wikiCatalogCardTitleClass
    , wikiCatalogGridAttr
    , wikiCatalogGridClass
    , wikiListMobileChromeOuterAttr
    , wikiRightRailSectionCardAttr
    , wikiRightRailSectionCardClass
    , wikiRightRailTocNudgeAttr
    )

import Html exposing (Attribute, Html)
import Html.Attributes as Attr
import Html.Events as Events
import Json.Decode
import TW
import UI.WikiPageRightRailMobile
import UI.ZIndex


classAttr : String -> Attribute msg
classAttr =
    TW.cls


minW0Attr : Attribute msg
minW0Attr =
    TW.cls "min-w-0"


markdownContainerAttr : Attribute msg
markdownContainerAttr =
    TW.cls markdownContainerClass


markdownParagraphAttr : Attribute msg
markdownParagraphAttr =
    TW.cls markdownParagraphClass


markdownBlockQuoteAttr : Attribute msg
markdownBlockQuoteAttr =
    TW.cls markdownBlockQuoteClass


markdownOrderedListAttr : Attribute msg
markdownOrderedListAttr =
    TW.cls markdownOrderedListClass


markdownListItemAttr : Attribute msg
markdownListItemAttr =
    TW.cls markdownListItemClass


markdownTableAttr : Attribute msg
markdownTableAttr =
    TW.cls markdownTableClass


markdownTableRowAttr : Attribute msg
markdownTableRowAttr =
    TW.cls markdownTableRowClass


markdownTableHeaderCellAttr : Attribute msg
markdownTableHeaderCellAttr =
    TW.cls markdownTableHeaderCellClass


markdownTableCellAttr : Attribute msg
markdownTableCellAttr =
    TW.cls markdownTableCellClass


markdownCodeBlockPreAttr : Attribute msg
markdownCodeBlockPreAttr =
    TW.cls markdownCodeBlockPreClass


markdownCodeBlockCodeAttr : Attribute msg
markdownCodeBlockCodeAttr =
    TW.cls markdownCodeBlockCodeClass


markdownThematicBreakAttr : Attribute msg
markdownThematicBreakAttr =
    TW.cls markdownThematicBreakClass


markdownTodoAttr : Attribute msg
markdownTodoAttr =
    TW.cls markdownTodoClass


stackAttr : Attribute msg
stackAttr =
    TW.cls "flex flex-col gap-3 min-w-0"


stackTightAttr : Attribute msg
stackTightAttr =
    TW.cls "flex flex-col gap-1.5 min-w-0"


clusterAttr : Attribute msg
clusterAttr =
    TW.cls "flex flex-wrap gap-2"


surfaceCardAttr : Attribute msg
surfaceCardAttr =
    TW.cls "border border-[var(--border-subtle)] bg-[var(--chrome-bg)] rounded-xl p-3"


inputTextAttr : Attribute msg
inputTextAttr =
    formTextInputAttr


inputTextFullAttr : Attribute msg
inputTextFullAttr =
    TW.cls (formTextInputClass ++ " w-full max-w-full")


{-| `Html.main_` in the app shell: overflow-y scroll region for article content. Used for in-page fragment scrolling (window scroll is not used; see `Frontend` Dom tasks).
-}
appMainScrollRegionId : String
appMainScrollRegionId =
    "app-main-scroll"


appRootClass : Bool -> String
appRootClass trimHorizontalPadding =
    "app-root flex flex-col h-dvh max-h-dvh min-h-0 overflow-hidden "
        ++ (if trimHorizontalPadding then
                "px-0 "

            else
                "px-[0.5rem] "
           )
        ++ "pb-0 [font-family:var(--font-ui)] bg-[var(--bg)] text-[var(--fg)] leading-[1.35]"


focusVisibleRingClass : String
focusVisibleRingClass =
    "focus-visible:outline-2 focus-visible:outline-[var(--focus-ring)] focus-visible:outline-offset-2"


contentParagraphClass : String
contentParagraphClass =
    "my-[1rem] leading-[1.6] [font-family:var(--font-serif)] first:mt-0"


contentParagraph : List (Attribute msg) -> List (Html msg) -> Html msg
contentParagraph attrs children =
    Html.p (TW.cls contentParagraphClass :: attrs) children


contentLabelClass : String
contentLabelClass =
    "block mt-[0.25rem] text-[0.8125rem] text-[var(--fg-muted)] [font-family:var(--font-ui)]"


contentLabel : List (Attribute msg) -> List (Html msg) -> Html msg
contentLabel attrs children =
    Html.label (TW.cls contentLabelClass :: attrs) children


{-| Single-line controls (`type=text`, `password`, …). Omit on `checkbox` / `radio`.
-}
formTextInputClass : String
formTextInputClass =
    "[font-family:var(--font-ui)] text-[0.8125rem] px-[0.5rem] py-[0.3rem] mt-[0.1rem] mb-[0.2rem] rounded-lg border border-[var(--border-subtle)] bg-[var(--input-bg)] text-[var(--fg)] max-w-full box-border "
        ++ focusVisibleRingClass


sidebarContainerClass : String
sidebarContainerClass =
    "min-h-0 self-stretch overflow-y-auto overscroll-contain flex flex-col gap-y-[0.9rem] bg-[var(--chrome-bg)] max-md:flex-none max-md:max-h-[50%] border-0 max-md:border-t max-md:border-[var(--border-subtle)] py-[0.85rem] px-[0.85rem] pr-0"


{-| Indents block content under `sidebarHeading` (same inset as the first ToC heading tier in `PageToc`).
-}
sidebarNavSectionBodyClass : String
sidebarNavSectionBodyClass =
    "pl-[0.35rem]"


tableBaseClass : String
tableBaseClass =
    "border-collapse text-[0.8125rem] leading-[1.35] border-t border-b border-[var(--border)] [&_th+th]:border-l [&_th+th]:border-[var(--border-dash)] [&_td+td]:border-l [&_td+td]:border-[var(--border-dash)] [&_tbody_tr:hover]:bg-[var(--table-row-hover)]"


tableAutoClass : String
tableAutoClass =
    "w-auto " ++ tableBaseClass


tableFullWidthMax72Class : String
tableFullWidthMax72Class =
    "w-full max-w-[72rem] " ++ tableBaseClass


tableHeaderCellClass : String
tableHeaderCellClass =
    "px-[0.55rem] py-[0.22rem] text-[0.8125rem] text-left align-top bg-[var(--chrome-bg)] font-semibold border-b border-[var(--border)]"


{-| Same as `tableHeaderCellClass` but vertically centers content (e.g. rows with buttons). Use `tableHeaderCellClass` when cell text may wrap across lines.
-}
tableHeaderCellMiddleClass : String
tableHeaderCellMiddleClass =
    "px-[0.55rem] py-[0.22rem] text-[0.8125rem] text-left align-middle bg-[var(--chrome-bg)] font-semibold border-b border-[var(--border)]"


tableCellClass : String
tableCellClass =
    "px-[0.55rem] py-[0.22rem] text-left align-top"


{-| Same as `tableCellClass` but vertically centers content. Use `tableCellClass` when multi-line cell text is expected.
-}
tableCellMiddleClass : String
tableCellMiddleClass =
    "px-[0.55rem] py-[0.22rem] text-left align-middle"


tableStripedRowClass : String
tableStripedRowClass =
    "even:bg-[var(--table-stripe)]"


{-| Fixed layout presets for `table` (width / max-width on the `table` element).
-}
type TableWidth
    = TableAuto
    | TableFullMax72


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


{-| Table body cell using reading serif (`--font-serif`), with the same vertical alignment as `tableTd`. For prose-like columns (e.g. wiki TODOs item text) while sibling cells stay UI sans.
-}
tableTdSerif : TableCellVerticalAlign -> List (Attribute msg) -> List (Html msg) -> Html msg
tableTdSerif align extraAttrs children =
    Html.td (TW.cls (cellClassForVerticalAlign align ++ " [font-family:var(--font-serif)]") :: extraAttrs) children


appHeaderSecondaryMetaClass : String
appHeaderSecondaryMetaClass =
    "text-[var(--fg-muted)] font-normal italic max-w-full gap-x-[0.9rem] flex flex-row"


appHeaderSecondaryAfterDividerClass : String
appHeaderSecondaryAfterDividerClass =
    "min-w-0"


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


appHeaderPrimaryPlainClass : String
appHeaderPrimaryPlainClass =
    "font-semibold"


appHeaderTitleRowClass : String
appHeaderTitleRowClass =
    "inline-flex items-center flex-wrap gap-x-[0.9rem] gap-y-[0.35rem] max-w-full"


appHeaderDividerClass : String
appHeaderDividerClass =
    "self-center w-0 h-[0.95em] my-0 border-l-2 border-[var(--border)]"


appHeaderBarClass : String
appHeaderBarClass =
    "relative overflow-visible "
        ++ UI.ZIndex.class UI.ZIndex.HeaderSearchLayer
        ++ " shrink-0 flex flex-row flex-wrap md:flex-nowrap items-center justify-between gap-y-[0.5rem] gap-x-[0.75rem] py-[0.55rem] border-b border-[var(--border-subtle)] shadow-[0_4px_20px_rgba(73,103,49,0.08)] backdrop-blur-sm max-md:pt-[max(0.55rem,env(safe-area-inset-top))] pl-[max(0.75rem,env(safe-area-inset-left))] pr-[max(0.75rem,env(safe-area-inset-right))]"


appHeaderH1Class : String
appHeaderH1Class =
    "m-0 text-[1.5rem] font-semibold leading-[1.2] text-[var(--fg)] flex-1 min-w-0 [font-family:var(--font-serif)]"


sideNavNavClass : String
sideNavNavClass =
    "w-full h-full min-h-0 flex flex-col"


sideNavStackClass : String
sideNavStackClass =
    "flex flex-col gap-y-[0.9rem] w-full text-[var(--fg-muted)] text-[0.8125rem] [font-family:var(--font-ui)] leading-[1.35]"


sideNavListClass : String
sideNavListClass =
    "list-none m-0 p-0 flex flex-col w-full"


sideNavBottomSectionClass : String
sideNavBottomSectionClass =
    "shrink-0"


sideNavMainSectionClass : String
sideNavMainSectionClass =
    "min-h-0 md:flex-1 md:overflow-y-auto md:overscroll-contain"


wikiCatalogGridClass : String
wikiCatalogGridClass =
    "grid w-full max-w-[72rem] grid-cols-1 md:grid-cols-3 gap-3"


hostAdminWikiDetailShellClass : String
hostAdminWikiDetailShellClass =
    "w-full min-w-0"


hostAdminWikiDetailGridClass : String
hostAdminWikiDetailGridClass =
    "grid grid-cols-[minmax(0,1fr)_17rem] gap-5 items-start"


hostAdminWikiDetailMainStackClass : String
hostAdminWikiDetailMainStackClass =
    "flex flex-col gap-3 min-w-0 max-w-[40rem]"


hostAdminWikiDetailSideStackClass : String
hostAdminWikiDetailSideStackClass =
    "flex flex-col gap-3 min-w-0"


hostAdminWikiDetailCardClass : String
hostAdminWikiDetailCardClass =
    "border border-[var(--border-subtle)] bg-[var(--chrome-bg)] rounded-xl p-4 shadow-[0_4px_16px_rgba(73,103,49,0.07)]"


hostAdminWikiDetailDangerCardClass : String
hostAdminWikiDetailDangerCardClass =
    "border border-[var(--danger)] bg-[var(--danger-bg)] rounded-xl p-4 shadow-[0_4px_16px_rgba(0,0,0,0.06)]"


hostAdminWikiDetailPageTitleClass : String
hostAdminWikiDetailPageTitleClass =
    "m-0 text-[1.35rem] font-semibold leading-[1.2] text-[var(--fg)]"


hostAdminWikiSlugClass : String
hostAdminWikiSlugClass =
    "[font-family:var(--font-mono)] text-[0.95rem] text-[var(--fg-muted)] break-all"


hostAdminWikiListSlugAttr : Attribute msg
hostAdminWikiListSlugAttr =
    TW.cls (hostAdminWikiSlugClass ++ " text-[0.8125rem]")


wikiCatalogCardClass : String
wikiCatalogCardClass =
    "block cursor-pointer border border-[var(--border-subtle)] bg-[var(--chrome-bg)] rounded-xl p-4 [font-family:var(--font-serif)] text-[inherit] no-underline shadow-[0_4px_16px_rgba(73,103,49,0.07)] hover:bg-[var(--bg)] hover:shadow-[0_8px_24px_rgba(73,103,49,0.12)] transition-[background-color,box-shadow] duration-200"


wikiCatalogCardTitleClass : String
wikiCatalogCardTitleClass =
    "m-0 text-[1.1rem] font-semibold"


wikiCatalogCardSlugEmClass : String
wikiCatalogCardSlugEmClass =
    "text-[0.9rem] font-normal opacity-80"


wikiCatalogCardSummaryClass : String
wikiCatalogCardSummaryClass =
    "m-0 mt-2 min-h-[1.25rem]"


markdownContainerClass : String
markdownContainerClass =
    "markdown-body block max-w-[52rem] text-[1rem] leading-[1.6] md:text-[1.125rem] [font-family:var(--font-serif)] [&>*:first-child]:mt-0 [&>*:first-child]:pt-0"


markdownParagraphClass : String
markdownParagraphClass =
    contentParagraphClass ++ " leading-[1.6]"


markdownTableClass : String
markdownTableClass =
    "my-[0.8rem] mb-[1rem] max-w-full w-auto " ++ tableBaseClass


markdownTableHeaderCellClass : String
markdownTableHeaderCellClass =
    tableHeaderCellClass


markdownTableCellClass : String
markdownTableCellClass =
    tableCellClass


markdownTableRowClass : String
markdownTableRowClass =
    tableStripedRowClass


markdownTodoClass : String
markdownTodoClass =
    "italic text-red-700 dark:text-red-400"


markdownBlockQuoteClass : String
markdownBlockQuoteClass =
    "my-[0.8rem] first:mt-0 pl-[0.9rem] pr-[0.2rem] border-l-[3px] border-[var(--border-subtle)] text-[var(--fg-muted)] [font-family:var(--font-serif)]"


markdownUnorderedListClass : String
markdownUnorderedListClass =
    "my-[0.25rem] first:mt-0 pl-[1.35rem] list-disc [font-family:var(--font-serif)]"


markdownOrderedListClass : String
markdownOrderedListClass =
    "my-[0.25rem] first:mt-0 pl-[1.35rem] list-decimal [font-family:var(--font-serif)]"


markdownListItemClass : String
markdownListItemClass =
    "my-[0.1rem] [font-family:var(--font-serif)]"


markdownCodeSpanClass : String
markdownCodeSpanClass =
    "[font-family:var(--font-mono)] text-[0.88em] bg-[var(--code-bg)] px-[0.2rem] py-[0.05rem]"


markdownCodeBlockPreClass : String
markdownCodeBlockPreClass =
    "[font-family:var(--font-mono)] my-[0.35rem] first:mt-0 px-[0.45rem] py-[0.35rem] overflow-x-auto bg-[var(--code-bg)] border border-[var(--border)] text-[0.85rem] leading-[1.4]"


markdownCodeBlockCodeClass : String
markdownCodeBlockCodeClass =
    "[font-family:var(--font-mono)] border-0 p-0 bg-transparent"


markdownThematicBreakClass : String
markdownThematicBreakClass =
    "my-[0.35rem] first:mt-0 border-0 border-t border-[var(--border)]"


backlinksSectionClass : String
backlinksSectionClass =
    "max-w-[52rem]"


backlinksListClass : String
backlinksListClass =
    "list-none m-0 p-0 flex flex-col"


{-| Pill-shaped tag link for the right-rail tags section.
-}
tagPillClass : Bool -> String
tagPillClass slugExists =
    "inline-block px-[0.35rem] py-[0.15rem] rounded-full border text-[0.8125rem] no-underline transition-colors duration-150 [font-family:var(--font-ui)] font-semibold "
        ++ (if slugExists then
                "border-[var(--tag-border)] bg-[var(--tag-bg)] text-[var(--tag-fg)] hover:brightness-[0.96] "

            else
                "border-[var(--danger)] border-dashed bg-[var(--bg)] text-[var(--danger)] cursor-pointer hover:bg-[var(--danger-link-bg-hover)] "
           )
        ++ focusVisibleRingClass


sidebarDesktopOnlyClass : String
sidebarDesktopOnlyClass =
    ""


{-| Centered card wrapper for auth/login/register forms. Provides max-width, rounded corners, and subtle organic shadow.
-}
formCenteredCardClass : String
formCenteredCardClass =
    "mx-auto mt-[3rem] mb-[3rem] max-w-[28rem] border border-[var(--border-subtle)] bg-[var(--auth-card-bg)] text-[var(--auth-card-fg)] rounded-2xl p-8 shadow-[0_8px_40px_rgba(0,0,0,0.2)]"


layoutLeftNavAsideClass : String
layoutLeftNavAsideClass =
    "self-stretch min-h-0 overflow-y-auto overscroll-contain leading-[1.35] text-[var(--fg)] text-[0.8125rem] bg-[var(--chrome-bg)] border-r border-[var(--border-subtle)] py-[0.85rem] pl-[0.85rem]"


layoutHolyGrailClass : Bool -> String
layoutHolyGrailClass trimHorizontalGutter =
    let
        horizontalGutterClass : String
        horizontalGutterClass =
            if trimHorizontalGutter then
                ""

            else
                " px-[0.5rem] -mx-[0.5rem]"
    in
    "relative flex min-h-0 min-w-0 h-full w-full flex-1 overflow-hidden flex-col md:flex-row md:items-stretch "
        ++ horizontalGutterClass


layoutMainColumnClass : Bool -> Bool -> Bool -> String
layoutMainColumnClass hasRightColumn trimRightPadding trimVerticalPadding =
    let
        verticalPaddingClass : String
        verticalPaddingClass =
            if trimVerticalPadding then
                "py-0"

            else
                "py-[0.85rem]"
    in
    if hasRightColumn then
        if trimRightPadding then
            "min-h-0 h-full flex-1 min-w-0 overflow-y-auto overscroll-contain bg-[var(--bg)] px-0 border-r border-[var(--border-subtle)] max-md:border-r-0 "
                ++ verticalPaddingClass

        else
            "min-h-0 h-full flex-1 min-w-0 overflow-y-auto overscroll-contain bg-[var(--bg)] px-[0.85rem] border-r border-[var(--border-subtle)] max-md:border-r-0 "
                ++ verticalPaddingClass

    else if trimRightPadding then
        "min-h-0 h-full flex-1 min-w-0 overflow-y-auto overscroll-contain bg-[var(--bg)] px-0 border-r-0 "
            ++ verticalPaddingClass

    else
        "min-h-0 h-full flex-1 min-w-0 overflow-y-auto overscroll-contain bg-[var(--bg)] pl-[0.85rem] pr-0 border-r-0 "
            ++ verticalPaddingClass


{-| Main column when the route owns internal scrolling (audit log: filters fixed, table scrolls). Replaces outer `overflow-y-auto` with `overflow-hidden flex flex-col`.
-}
layoutMainColumnClassAuditFill : Bool -> Bool -> Bool -> String
layoutMainColumnClassAuditFill hasRightColumn trimRightPadding trimVerticalPadding =
    let
        verticalPaddingClass : String
        verticalPaddingClass =
            if trimVerticalPadding then
                "py-0"

            else
                "py-[0.85rem]"
    in
    if hasRightColumn then
        if trimRightPadding then
            "min-h-0 h-full flex-1 min-w-0 flex flex-col overflow-hidden overscroll-contain bg-[var(--bg)] px-0 border-r border-[var(--border-subtle)] max-md:border-r-0 "
                ++ verticalPaddingClass

        else
            "min-h-0 h-full flex-1 min-w-0 flex flex-col overflow-hidden overscroll-contain bg-[var(--bg)] px-[0.85rem] border-r border-[var(--border-subtle)] max-md:border-r-0 "
                ++ verticalPaddingClass

    else if trimRightPadding then
        "min-h-0 h-full flex-1 min-w-0 flex flex-col overflow-hidden overscroll-contain bg-[var(--bg)] px-0 border-r-0 "
            ++ verticalPaddingClass

    else
        "min-h-0 h-full flex-1 min-w-0 flex flex-col overflow-hidden overscroll-contain bg-[var(--bg)] pl-[0.85rem] pr-0 border-r-0 "
            ++ verticalPaddingClass


markdownPreviewScrollClass : String
markdownPreviewScrollClass =
    "max-h-[24rem] min-w-0 overflow-scroll [scrollbar-gutter:stable] bg-[var(--bg)] px-2 pb-2 pt-0 [font-family:var(--font-serif)]"


auditTableBaseClass : String
auditTableBaseClass =
    "w-full table-auto border-separate border-spacing-0 text-[0.8125rem] leading-[1.35] border-[var(--border)] [&_th+th]:border-l [&_th+th]:border-[var(--border-dash)] [&_td+td]:border-l [&_td+td]:border-[var(--border-dash)] [&_tbody_tr:hover]:bg-[var(--table-row-hover)]"


auditTableHeaderTableClass : String
auditTableHeaderTableClass =
    auditTableBaseClass ++ " border-t border-b"


auditTableBodyTableClass : String
auditTableBodyTableClass =
    auditTableBaseClass ++ " border-b border-t-0"


auditTableHeaderCellClass : String
auditTableHeaderCellClass =
    "sticky top-0 "
        ++ UI.ZIndex.class UI.ZIndex.AuditTableHeader
        ++ " px-[0.55rem] py-[0.22rem] text-[0.8125rem] text-left align-top bg-[var(--chrome-bg)] font-semibold border-b border-[var(--border)]"


newPageEditorMarkdownPreviewCellClass : String
newPageEditorMarkdownPreviewCellClass =
    "flex min-h-0 min-w-0 flex-col gap-1 h-full"


appRootClassAttr : { isDark : Bool, trimHorizontalPadding : Bool } -> Attribute msg
appRootClassAttr { isDark, trimHorizontalPadding } =
    TW.cls
        (if isDark then
            appRootClass trimHorizontalPadding ++ " dark"

         else
            appRootClass trimHorizontalPadding
        )


layoutHolyGrailAttr : { hasRightColumn : Bool, trimHorizontalGutter : Bool } -> Attribute msg
layoutHolyGrailAttr { trimHorizontalGutter } =
    TW.cls (layoutHolyGrailClass trimHorizontalGutter)


layoutMainColumnForRouteAttr : { hasRightColumn : Bool, auditFill : Bool, trimRightPadding : Bool, trimVerticalPadding : Bool } -> Attribute msg
layoutMainColumnForRouteAttr { hasRightColumn, auditFill, trimRightPadding, trimVerticalPadding } =
    TW.cls
        (if auditFill then
            layoutMainColumnClassAuditFill hasRightColumn trimRightPadding trimVerticalPadding

         else
            layoutMainColumnClass hasRightColumn trimRightPadding trimVerticalPadding
        )


mainContentPaddingAttr : Attribute msg
mainContentPaddingAttr =
    TW.cls "px-[0.85rem] py-[0.85rem]"


{-| `id` on the mobile off-canvas nav panel for focus management.
-}
mobileSideNavDrawerId : String
mobileSideNavDrawerId =
    "mobile-side-nav-drawer"


mobileNavBackdropClass : String
mobileNavBackdropClass =
    "absolute inset-0 bg-black/35 md:hidden " ++ UI.ZIndex.class UI.ZIndex.MobileNavDrawer


mobileWikiNavBackdropView : msg -> Html msg
mobileWikiNavBackdropView onClose =
    Html.div
        [ TW.cls mobileNavBackdropClass
        , Events.onClick onClose
        , Attr.attribute "aria-hidden" "true"
        ]
        []


mobileSideNavAsideAttrs : Bool -> msg -> List (Attribute msg)
mobileSideNavAsideAttrs open onClose =
    [ TW.cls (mobileSideNavAsideClass open)
    , Attr.id mobileSideNavDrawerId
    , Attr.tabindex -1
    , mobileNavEscapeAttr onClose
    ]


mobileOnlySideNavAsideAttrs : Bool -> msg -> List (Attribute msg)
mobileOnlySideNavAsideAttrs open onClose =
    [ TW.cls (mobileSideNavAsideClass open ++ " md:hidden")
    , Attr.id mobileSideNavDrawerId
    , Attr.tabindex -1
    , mobileNavEscapeAttr onClose
    ]


mobileSideNavAsideClass : Bool -> String
mobileSideNavAsideClass open =
    let
        translateClass : String
        translateClass =
            if open then
                "translate-x-0 "

            else
                "-translate-x-full "
    in
    translateClass
        ++ UI.ZIndex.class UI.ZIndex.MobileNavDrawer
        ++ " mobile-side-nav-drawer absolute left-0 top-0 bottom-0 max-md:w-fit max-md:min-w-[max(200px,50%)] max-md:max-w-[100dvw] flex flex-col min-h-0 overflow-y-auto overscroll-contain leading-[1.35] text-[var(--fg)] text-[0.8125rem] bg-[var(--chrome-bg)] border-r border-[var(--border-subtle)] py-[0.85rem] pl-[max(0.85rem,env(safe-area-inset-left))] pr-[0.65rem] pb-[env(safe-area-inset-bottom)] transition-transform duration-200 ease-out motion-reduce:transition-none motion-reduce:duration-0 shadow-[4px_0_24px_rgba(0,0,0,0.12)] md:shadow-none md:static md:inset-auto md:top-auto md:bottom-auto md:h-auto md:self-stretch md:w-[12.5rem] md:max-w-none md:translate-x-0 md:flex-shrink-0 md:overflow-y-auto md:py-[0.85rem] md:pl-[0.85rem] md:pr-0 md:pb-[0.85rem]"


wikiChromeInnerGridClass : Bool -> String
wikiChromeInnerGridClass hasRightColumn =
    if hasRightColumn then
        "flex flex-col flex-1 min-h-0 h-full w-full min-w-0 overflow-hidden md:grid md:min-h-0 md:grid-cols-[minmax(0,1fr)_minmax(10rem,14rem)] md:items-stretch"

    else
        "flex flex-col flex-1 min-h-0 h-full w-full min-w-0 overflow-hidden"


mobileNavEscapeAttr : msg -> Attribute msg
mobileNavEscapeAttr onClose =
    Events.on "keydown"
        (Json.Decode.field "key" Json.Decode.string
            |> Json.Decode.andThen
                (\key ->
                    if key == "Escape" then
                        Json.Decode.succeed onClose

                    else
                        Json.Decode.fail "not escape"
                )
        )


wikiListMobileChromeOuterAttr : Attribute msg
wikiListMobileChromeOuterAttr =
    TW.cls "relative flex min-h-0 min-w-0 flex-1 flex-col overflow-hidden bg-[var(--chrome-bg)]"


holyGrailLayout :
    { hasRightColumn : Bool
    , trimHorizontalGutter : Bool
    , mobileSideNavOpen : Bool
    , onCloseMobileNav : msg
    , leftNav : Html msg
    , mainAttributes : List (Attribute msg)
    , mainBody : Html msg
    , rightRailSections : List (Html msg)
    , wikiPageMobileRightRail : Maybe { collapsed : Bool, onToggle : msg }
    }
    -> Html msg
holyGrailLayout config =
    Html.div
        [ layoutHolyGrailAttr
            { hasRightColumn = config.hasRightColumn
            , trimHorizontalGutter = config.trimHorizontalGutter
            }
        ]
        (List.concat
            [ if config.mobileSideNavOpen then
                [ mobileWikiNavBackdropView config.onCloseMobileNav ]

              else
                []
            , [ Html.aside
                    (mobileSideNavAsideAttrs config.mobileSideNavOpen config.onCloseMobileNav)
                    [ config.leftNav ]
              , Html.div
                    [ TW.cls (wikiChromeInnerGridClass config.hasRightColumn) ]
                    (List.concat
                        [ [ Html.main_ config.mainAttributes [ config.mainBody ] ]
                        , if List.isEmpty config.rightRailSections then
                            []

                          else
                            [ Html.aside [ wikiPageMobileRightRailAsideAttr config.wikiPageMobileRightRail ]
                                (wikiPageMobileRightRailAsideChildren config.wikiPageMobileRightRail config.rightRailSections)
                            ]
                        ]
                    )
              ]
            ]
        )


wikiPageMobileRightRailAsideAttr : Maybe { collapsed : Bool, onToggle : msg } -> Attribute msg
wikiPageMobileRightRailAsideAttr wikiRail =
    case wikiRail of
        Just rail ->
            if rail.collapsed then
                TW.cls
                    (sidebarContainerClass
                        ++ " max-md:max-h-none max-md:flex-shrink-0 max-md:overflow-visible max-md:gap-y-0 max-md:py-0 max-md:px-0"
                    )

            else
                TW.cls
                    (sidebarContainerClass
                        ++ " max-md:px-0 max-md:pt-0 max-md:pb-[0.85rem]"
                    )

        Nothing ->
            sidebarContainerAttr


wikiPageMobileRightRailSectionsWrapperAttrForJust : Bool -> Attribute msg
wikiPageMobileRightRailSectionsWrapperAttrForJust collapsed =
    {- Mobile: wrapper stacks toggle + rail and handles collapsed visibility.
       Desktop (`md:`): `contents` removes box so inner rail grid keeps `md:contents`
       and aside `gap-y` applies between section cards unchanged.
    -}
    if collapsed then
        TW.cls "min-h-0 flex flex-1 flex-col max-md:hidden md:contents"

    else
        {- Aside uses max-md:px-0 so Metadata row is edge-to-edge; restore inset for rail sections only on mobile. -}
        TW.cls "min-h-0 flex flex-1 flex-col max-md:px-[0.85rem] md:contents"


wikiPageMobileRightRailAsideChildren :
    Maybe { collapsed : Bool, onToggle : msg }
    -> List (Html msg)
    -> List (Html msg)
wikiPageMobileRightRailAsideChildren wikiRail sections =
    case wikiRail of
        Nothing ->
            rightRailSectionCards sections

        Just rail ->
            [ UI.WikiPageRightRailMobile.toggleRailButton
                { expanded = not rail.collapsed
                , onToggle = rail.onToggle
                }
            , Html.div [ wikiPageMobileRightRailSectionsWrapperAttrForJust rail.collapsed ]
                (rightRailSectionCards sections)
            ]


rightRailSectionCards : List (Html msg) -> List (Html msg)
rightRailSectionCards sections =
    [ Html.div
        [ TW.cls "w-full max-md:grid max-md:grid-cols-3 max-md:gap-3 md:contents" ]
        (List.map
            (\section ->
                Html.div
                    [ wikiRightRailSectionCardAttr ]
                    [ section ]
            )
            sections
        )
    ]


auditMainColumnBodyInnerAttr : Attribute msg
auditMainColumnBodyInnerAttr =
    TW.cls "flex min-h-0 min-w-0 flex-1 flex-col"


auditLogCol : String -> Html msg
auditLogCol columnClass =
    Html.node "col" [ TW.cls columnClass ] []


auditLogColGroup : List String -> Html msg
auditLogColGroup columnClasses =
    Html.node "colgroup" [] (List.map auditLogCol columnClasses)


auditLogHeaderRow : List String -> Html msg
auditLogHeaderRow labels =
    Html.tr []
        (List.map
            (\labelText ->
                Html.th
                    [ Attr.scope "col"
                    , TW.cls auditTableHeaderCellClass
                    ]
                    [ Html.text labelText ]
            )
            labels
        )


{-| Sticky filter + scrollable body pattern for wiki/host audit tables.
-}
auditLogTableView :
    { tableId : String
    , tbodyId : String
    , columnClasses : List String
    , headers : List String
    , rows : List (Html msg)
    }
    -> Html msg
auditLogTableView config =
    Html.div
        [ TW.cls "flex min-h-0 min-w-0 flex-1 flex-col overflow-hidden" ]
        [ Html.div
            [ TW.cls "min-h-0 min-w-0 flex-1 overflow-auto overscroll-none" ]
            [ Html.table
                [ Attr.id config.tableId
                , TW.cls auditTableBaseClass
                ]
                [ auditLogColGroup config.columnClasses
                , Html.thead [] [ auditLogHeaderRow config.headers ]
                , Html.tbody [ Attr.id config.tbodyId ] config.rows
                ]
            ]
        ]


formTextInputAuditFilterClass : String
formTextInputAuditFilterClass =
    formTextInputClass ++ " mt-0 w-full max-w-full"


formTextInputHostAdminSlugClass : String
formTextInputHostAdminSlugClass =
    formTextInputClass ++ " " ++ hostAdminWikiSlugClass ++ " w-full max-w-full"


tableCellMonoTimestampClass : String
tableCellMonoTimestampClass =
    tableCellClass ++ " [font-family:var(--font-mono)] whitespace-nowrap text-[0.8125rem]"


viewDiffKindInlineAttr : Attribute msg
viewDiffKindInlineAttr =
    TW.cls "inline-flex flex-wrap items-center gap-2"


hostAdminBackupCardAttr : Attribute msg
hostAdminBackupCardAttr =
    TW.cls "mb-8 max-w-3xl"


formFeedbackTextSmAttr : Attribute msg
formFeedbackTextSmAttr =
    TW.cls "mb-3 text-[0.8125rem] leading-[1.4] text-[var(--fg-muted)]"


formStackMb3Attr : Attribute msg
formStackMb3Attr =
    TW.cls "mb-3"


mb3Attr : Attribute msg
mb3Attr =
    TW.cls "mb-3"


mb2Attr : Attribute msg
mb2Attr =
    TW.cls "mb-2"


mt3Mb3Attr : Attribute msg
mt3Mb3Attr =
    TW.cls "mt-3 mb-3"


flexWrapGap1Attr : Attribute msg
flexWrapGap1Attr =
    TW.cls "flex flex-wrap gap-1"


flexWrapGap2Attr : Attribute msg
flexWrapGap2Attr =
    TW.cls "flex flex-wrap gap-2"


flexWrapGap2Mt3Attr : Attribute msg
flexWrapGap2Mt3Attr =
    TW.cls "flex flex-wrap gap-2 mt-3"


flexRowMin0Attr : Attribute msg
flexRowMin0Attr =
    TW.cls "flex min-h-0 min-w-0 flex-1 flex-col overflow-hidden"


flexColMin0Gap3Attr : Attribute msg
flexColMin0Gap3Attr =
    TW.cls "flex min-h-0 flex-1 flex-col gap-3"


hostAdminAuditPageShellAttr : Attribute msg
hostAdminAuditPageShellAttr =
    flexColMin0Gap3Attr


wikiAdminAuditPageShellAttr : Attribute msg
wikiAdminAuditPageShellAttr =
    TW.cls "flex min-h-0 flex-1 flex-col"


hostAdminAuditDiffPageShellAttr : Attribute msg
hostAdminAuditDiffPageShellAttr =
    TW.cls "flex min-h-0 flex-1 flex-col gap-3 overflow-auto"


hostAdminAuditFiltersCardAttr : Attribute msg
hostAdminAuditFiltersCardAttr =
    TW.cls "shrink-0 border-b border-[var(--border-subtle)] bg-[var(--bg)] px-4 py-3"


hostAdminAuditFiltersGridAttr : Attribute msg
hostAdminAuditFiltersGridAttr =
    TW.cls "grid grid-cols-3 gap-3"


wikiAdminAuditFiltersGridAttr : Attribute msg
wikiAdminAuditFiltersGridAttr =
    TW.cls "grid grid-cols-2 gap-3"


formFieldMinW0Attr : Attribute msg
formFieldMinW0Attr =
    TW.cls "min-w-0"


formFieldLabelBlockAttr : Attribute msg
formFieldLabelBlockAttr =
    TW.cls "block text-[0.8125rem] font-medium text-[var(--fg-muted)]"


auditFilterTypeGroupAttr : Attribute msg
auditFilterTypeGroupAttr =
    TW.cls "mt-1.5 pt-1.5"


auditFilterLegendTextAttr : Attribute msg
auditFilterLegendTextAttr =
    TW.cls "m-0 mb-2 text-[0.8125rem] text-[var(--fg-muted)]"


hostAdminWikiDetailFormStackAttr : Attribute msg
hostAdminWikiDetailFormStackAttr =
    TW.cls "mt-1.5 flex flex-col gap-1 min-w-0"


hostAdminCardParagraphTightAttr : Attribute msg
hostAdminCardParagraphTightAttr =
    TW.cls "m-0 mb-1.5 text-[0.8125rem] leading-[1.4] text-[var(--fg)]"


hostAdminStatusParaAttr : Attribute msg
hostAdminStatusParaAttr =
    TW.cls "m-0 mb-1.5 text-[0.8125rem] leading-[1.4] text-[var(--fg)]"


hostAdminDangerBlurbAttr : Attribute msg
hostAdminDangerBlurbAttr =
    TW.cls "m-0 mb-2 text-[0.8125rem] leading-[1.4] text-[var(--fg)]"


hostAdminDeleteFormStackAttr : Attribute msg
hostAdminDeleteFormStackAttr =
    TW.cls "flex flex-col gap-1.5 min-w-0"


gridTwoColEditorStrAttr : Attribute msg
gridTwoColEditorStrAttr =
    TW.cls "grid min-w-0 grid-cols-2 gap-4 items-stretch"


gridTwoByTwoDiffStrAttr : Attribute msg
gridTwoByTwoDiffStrAttr =
    TW.cls "grid min-w-0 grid-cols-2 grid-rows-2 gap-4 items-stretch"


gridCellCol2Row2Attr : Attribute msg
gridCellCol2Row2Attr =
    TW.cls "min-w-0 col-start-2 row-start-2"


gridCellStackCol1Row3Attr : Attribute msg
gridCellStackCol1Row3Attr =
    TW.cls "flex min-h-0 min-w-0 flex-col gap-1 col-start-1 row-start-3"


gridCellStackCol2Row3Attr : Attribute msg
gridCellStackCol2Row3Attr =
    TW.cls "flex min-h-0 min-w-0 flex-col gap-1 col-start-2 row-start-3"


markdownPreviewScrollMinFlexAttr : Attribute msg
markdownPreviewScrollMinFlexAttr =
    TW.cls (markdownPreviewScrollClass ++ " min-h-0 flex-1")


markdownPreviewScrollMinFlexFullHeightAttr : Attribute msg
markdownPreviewScrollMinFlexFullHeightAttr =
    TW.cls (markdownPreviewScrollClass ++ " min-h-0 h-full flex-1")


newPageEditorMarkdownPreviewCellAttr : Attribute msg
newPageEditorMarkdownPreviewCellAttr =
    TW.cls newPageEditorMarkdownPreviewCellClass


sidebarNavSectionBodyStackAttr : Attribute msg
sidebarNavSectionBodyStackAttr =
    TW.cls (sidebarNavSectionBodyClass ++ " flex flex-col gap-[0.25rem]")


sidebarNavHorizontalIndentAttr : Attribute msg
sidebarNavHorizontalIndentAttr =
    TW.cls "pl-[0.35rem]"


tableCellMonoTimestampAttr : Attribute msg
tableCellMonoTimestampAttr =
    TW.cls tableCellMonoTimestampClass


formCenteredCardAttr : Attribute msg
formCenteredCardAttr =
    TW.cls formCenteredCardClass


formTextInputAttr : Attribute msg
formTextInputAttr =
    TW.cls formTextInputClass


formTextInputAuditFilterAttr : Attribute msg
formTextInputAuditFilterAttr =
    TW.cls formTextInputAuditFilterClass


formTextInputHostAdminSlugAttr : Attribute msg
formTextInputHostAdminSlugAttr =
    TW.cls formTextInputHostAdminSlugClass



-- | `TW.cls` aliases for `Frontend` (no `import TW` there).


appHeaderBarAttr : Attribute msg
appHeaderBarAttr =
    TW.cls appHeaderBarClass


appHeaderDividerAttr : Attribute msg
appHeaderDividerAttr =
    TW.cls appHeaderDividerClass


appHeaderH1Attr : Attribute msg
appHeaderH1Attr =
    TW.cls appHeaderH1Class


appHeaderPrimaryPlainAttr : Attribute msg
appHeaderPrimaryPlainAttr =
    TW.cls appHeaderPrimaryPlainClass


appHeaderSecondaryAfterDividerAttr : Attribute msg
appHeaderSecondaryAfterDividerAttr =
    TW.cls appHeaderSecondaryAfterDividerClass


appHeaderSecondaryBracketAttr : Attribute msg
appHeaderSecondaryBracketAttr =
    TW.cls appHeaderSecondaryBracketClass


appHeaderSecondaryMetaAttr : Attribute msg
appHeaderSecondaryMetaAttr =
    TW.cls appHeaderSecondaryMetaClass


appHeaderSecondaryWikiLabelEmAttr : Attribute msg
appHeaderSecondaryWikiLabelEmAttr =
    TW.cls appHeaderSecondaryWikiLabelEmClass


appHeaderSecondaryWikiWrapAttr : Attribute msg
appHeaderSecondaryWikiWrapAttr =
    TW.cls appHeaderSecondaryWikiWrapClass


appHeaderTitleRowAttr : Attribute msg
appHeaderTitleRowAttr =
    TW.cls appHeaderTitleRowClass


backlinksListAttr : Attribute msg
backlinksListAttr =
    TW.cls backlinksListClass


backlinksSectionAttr : Attribute msg
backlinksSectionAttr =
    TW.cls backlinksSectionClass


hostAdminWikiDetailCardAttr : Attribute msg
hostAdminWikiDetailCardAttr =
    TW.cls hostAdminWikiDetailCardClass


hostAdminWikiDetailDangerCardAttr : Attribute msg
hostAdminWikiDetailDangerCardAttr =
    TW.cls hostAdminWikiDetailDangerCardClass


hostAdminWikiDetailGridAttr : Attribute msg
hostAdminWikiDetailGridAttr =
    TW.cls hostAdminWikiDetailGridClass


hostAdminWikiDetailMainStackAttr : Attribute msg
hostAdminWikiDetailMainStackAttr =
    TW.cls hostAdminWikiDetailMainStackClass


hostAdminWikiDetailPageTitleAttr : Attribute msg
hostAdminWikiDetailPageTitleAttr =
    TW.cls hostAdminWikiDetailPageTitleClass


hostAdminWikiDetailShellAttr : Attribute msg
hostAdminWikiDetailShellAttr =
    TW.cls hostAdminWikiDetailShellClass


hostAdminWikiDetailSideStackAttr : Attribute msg
hostAdminWikiDetailSideStackAttr =
    TW.cls hostAdminWikiDetailSideStackClass


layoutLeftNavAsideAttr : Attribute msg
layoutLeftNavAsideAttr =
    TW.cls layoutLeftNavAsideClass


markdownCodeSpanAttr : Attribute msg
markdownCodeSpanAttr =
    TW.cls markdownCodeSpanClass


markdownUnorderedListAttr : Attribute msg
markdownUnorderedListAttr =
    TW.cls markdownUnorderedListClass


pageActionsSidebarStackAttr : Attribute msg
pageActionsSidebarStackAttr =
    TW.cls "flex flex-col"


formFeedbackRowAttr : Attribute msg
formFeedbackRowAttr =
    TW.cls "mb-3 text-[0.8125rem] leading-[1.4] text-[var(--fg-muted)]"


tagPillAttr : Bool -> Attribute msg
tagPillAttr slugExists =
    TW.cls (tagPillClass slugExists)


tagPillsListAttr : Attribute msg
tagPillsListAttr =
    TW.cls "list-none m-0 p-0 flex flex-wrap gap-[0.35rem]"


sidebarM0Attr : Attribute msg
sidebarM0Attr =
    TW.cls "m-0 [font-family:var(--font-ui)] text-[0.8125rem] leading-[1.35] text-[var(--fg-muted)]"


todosListDiscAttr : Attribute msg
todosListDiscAttr =
    TW.cls "m-0 pl-[1.15rem] list-disc [font-family:var(--font-ui)] text-[0.8125rem] leading-[1.35]"


wikiRightRailTocNudgeAttr : Attribute msg
wikiRightRailTocNudgeAttr =
    TW.cls "-mx-[0.85rem] px-[0.85rem]"


wikiRightRailSectionCardClass : String
wikiRightRailSectionCardClass =
    "-ml-[0.85rem] w-[calc(100%+0.85rem)] px-[0.85rem] pt-3 border-t border-[var(--border-subtle)] first:border-t-0 first:pt-0 max-md:ml-0 max-md:w-auto max-md:px-0 max-md:pt-0 max-md:border-t-0"


wikiRightRailSectionCardAttr : Attribute msg
wikiRightRailSectionCardAttr =
    TW.cls wikiRightRailSectionCardClass


pageActionsTopBorderBlockAttr : Attribute msg
pageActionsTopBorderBlockAttr =
    TW.cls "mt-4 -mx-[0.85rem] px-[0.85rem] border-t border-[var(--border)] pt-4"


sidebarTocListRootAttr : Attribute msg
sidebarTocListRootAttr =
    TW.cls "my-0"


sidebarTocListIndentAttr : Attribute msg
sidebarTocListIndentAttr =
    TW.cls "flex flex-col"


submissionGridTight2ColAttr : Attribute msg
submissionGridTight2ColAttr =
    TW.cls "grid min-w-0 grid-cols-2 gap-x-3 gap-y-2"


reviewDiffNewPagePreviewColShellAttr : Attribute msg
reviewDiffNewPagePreviewColShellAttr =
    TW.cls "flex min-h-0 min-w-0 h-full col-start-2 row-start-2"


reviewDeletePagePreviewTitleAttr : Attribute msg
reviewDeletePagePreviewTitleAttr =
    TW.cls "m-0 text-[0.8125rem] font-semibold text-[var(--fg-muted)]"


reviewFieldsetAttr : Attribute msg
reviewFieldsetAttr =
    TW.cls "mt-4 flex flex-col gap-3 border border-[var(--border)] p-3 max-w-[42rem]"


reviewLegendAttr : Attribute msg
reviewLegendAttr =
    TW.cls "px-1 text-[var(--fg)]"


reviewRadioColumnAttr : Attribute msg
reviewRadioColumnAttr =
    TW.cls "flex flex-col gap-3"


reviewRadioRowAttr : Attribute msg
reviewRadioRowAttr =
    TW.cls "flex items-start gap-2 cursor-pointer"


reviewOptionLabelStrongAttr : Attribute msg
reviewOptionLabelStrongAttr =
    TW.cls "font-medium"


reviewNestedNoteColumnAttr : Attribute msg
reviewNestedNoteColumnAttr =
    TW.cls "flex flex-col gap-1.5"


submissionStatusDangerLineAttr : Attribute msg
submissionStatusDangerLineAttr =
    TW.cls "text-[var(--danger)] m-0 mt-2"


submitActionsBarAttr : Attribute msg
submitActionsBarAttr =
    mt3Mb3Attr


submitSummaryParagraphAttr : Attribute msg
submitSummaryParagraphAttr =
    TW.cls "m-0 text-[0.8125rem] leading-[1.45]"


sidebarContainerAttr : Attribute msg
sidebarContainerAttr =
    TW.cls sidebarContainerClass


sidebarDesktopOnlyAttr : Attribute msg
sidebarDesktopOnlyAttr =
    TW.cls sidebarDesktopOnlyClass


sidebarNavSectionBodyAttr : Attribute msg
sidebarNavSectionBodyAttr =
    TW.cls sidebarNavSectionBodyClass


sideNavListAttr : Attribute msg
sideNavListAttr =
    TW.cls sideNavListClass


sideNavBottomSectionAttr : Attribute msg
sideNavBottomSectionAttr =
    TW.cls sideNavBottomSectionClass


sideNavMainSectionAttr : Attribute msg
sideNavMainSectionAttr =
    TW.cls sideNavMainSectionClass


sideNavNavAttr : Attribute msg
sideNavNavAttr =
    TW.cls sideNavNavClass


sideNavStackAttr : Attribute msg
sideNavStackAttr =
    TW.cls sideNavStackClass


wikiCatalogCardAttr : Attribute msg
wikiCatalogCardAttr =
    TW.cls wikiCatalogCardClass


wikiCatalogCardSlugEmAttr : Attribute msg
wikiCatalogCardSlugEmAttr =
    TW.cls wikiCatalogCardSlugEmClass


wikiCatalogCardSummaryAttr : Attribute msg
wikiCatalogCardSummaryAttr =
    TW.cls wikiCatalogCardSummaryClass


wikiCatalogCardTitleAttr : Attribute msg
wikiCatalogCardTitleAttr =
    TW.cls wikiCatalogCardTitleClass


wikiCatalogGridAttr : Attribute msg
wikiCatalogGridAttr =
    TW.cls wikiCatalogGridClass
