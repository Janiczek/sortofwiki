module PageToc exposing (Entry, entries, view)

import Html exposing (Html)
import Html.Attributes as Attr
import Markdown.Block as Block
import Page
import TW
import UI
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
entries : Wiki.Slug -> (Page.Slug -> Bool) -> Page.FrontendDetails -> List Entry
entries wikiSlug publishedSlugExists pageDetails =
    WikiPageMarkdownParse.blocksWithHeadingSlugs wikiSlug publishedSlugExists pageDetails.markdownSource
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
        let
            minHeadingInt : Int
            minHeadingInt =
                tocEntries
                    |> List.map (.level >> headingLevelToInt)
                    |> List.minimum
                    |> Maybe.withDefault 1
        in
        Html.nav
            [ TW.cls "font-serif"
            , Attr.id "page-article-toc"
            , Attr.attribute "aria-label" "On this page"
            ]
            [ UI.sidebarHeading "On this page"
            , Html.div [ TW.cls UI.sidebarNavSectionBodyClass ]
                [ Html.ul [ TW.cls (UI.sideNavListClass ++ " leading-[1.3]") ]
                    (tocEntries
                        |> List.map
                            (\e ->
                                Html.li
                                    [ TW.cls ("m-0 " ++ entryIndentClass minHeadingInt e.level) ]
                                    [ UI.sidebarLink
                                        [ Attr.href ("#" ++ e.slug) ]
                                        [ Html.text e.label ]
                                    ]
                            )
                    )
                ]
            ]


headingLevelToInt : Block.HeadingLevel -> Int
headingLevelToInt level =
    case level of
        Block.H1 ->
            1

        Block.H2 ->
            2

        Block.H3 ->
            3

        Block.H4 ->
            4

        Block.H5 ->
            5

        Block.H6 ->
            6


{-| Indent nested headings relative to the shallowest heading in this page’s ToC so the top tier lines up with other sidebar nav links (body already applies `sidebarNavSectionBodyClass`).
-}
entryIndentClass : Int -> Block.HeadingLevel -> String
entryIndentClass minHeadingInt level =
    relativeIndentStepClass
        (Basics.clamp 0 5 (headingLevelToInt level - minHeadingInt))


relativeIndentStepClass : Int -> String
relativeIndentStepClass step =
    case step of
        0 ->
            "pl-0"

        1 ->
            "pl-[0.35rem]"

        2 ->
            "pl-[0.65rem]"

        3 ->
            "pl-[0.95rem]"

        4 ->
            "pl-[1.25rem]"

        5 ->
            "pl-[1.55rem]"

        _ ->
            "pl-[1.55rem]"
