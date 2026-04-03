module PageToc exposing (Entry, entries, view)

import Html exposing (Html)
import Html.Attributes as Attr
import Markdown.Block as Block
import Page
import TW
import Wiki
import WikiPageMarkdownParse


{-| One heading line in the in-page table of contents.
-}
type alias Entry =
    { level : Block.HeadingLevel
    , label : String
    , slug : String
    }


{-| Extract TOC entries from published page markdown (empty if parse fails or no headings).
-}
entries : Wiki.Slug -> Page.FrontendDetails -> List Entry
entries wikiSlug pageDetails =
    WikiPageMarkdownParse.blocksWithHeadingSlugs wikiSlug pageDetails.markdownSource
        |> Result.map entriesFromBlocksWithSlugMeta
        |> Result.withDefault []


entriesFromBlocksWithSlugMeta : List ( Block.Block, Maybe String ) -> List Entry
entriesFromBlocksWithSlugMeta =
    List.filterMap
        (\( block, maybeSlug ) ->
            case ( block, maybeSlug ) of
                ( Block.Heading level inlines, Just slug ) ->
                    Just
                        { level = level
                        , label = Block.extractInlineText inlines
                        , slug = slug
                        }

                _ ->
                    Nothing
        )


{-| Sidebar table of contents; pass only non-empty `entries` from the layout.
-}
view : List Entry -> Html msg
view tocEntries =
    if List.isEmpty tocEntries then
        Html.text ""

    else
        Html.nav
            [ TW.cls "font-serif"
            , Attr.id "page-article-toc"
            , Attr.attribute "aria-label" "On this page"
            ]
            [ Html.h2 [ TW.cls "m-0 mb-[0.35rem] text-[0.82rem] font-semibold uppercase tracking-[0.04em] text-[var(--fg-muted)]" ]
                [ Html.text "On this page" ]
            , Html.ul [ TW.cls "list-none m-0 p-0 flex flex-col gap-[0.25rem]" ]
                (tocEntries
                    |> List.map
                        (\e ->
                            Html.li
                                [ TW.cls ("m-0 leading-[1.3] " ++ headingLevelClass e.level) ]
                                [ Html.a
                                    [ Attr.href ("#" ++ e.slug) ]
                                    [ Html.text e.label ]
                                ]
                        )
                )
            ]


headingLevelClass : Block.HeadingLevel -> String
headingLevelClass level =
    case level of
        Block.H1 ->
            "pl-0"

        Block.H2 ->
            "pl-[0.35rem]"

        Block.H3 ->
            "pl-[0.65rem]"

        Block.H4 ->
            "pl-[0.95rem]"

        Block.H5 ->
            "pl-[1.25rem]"

        Block.H6 ->
            "pl-[1.55rem]"
