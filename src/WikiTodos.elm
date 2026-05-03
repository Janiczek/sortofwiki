module WikiTodos exposing (MissingPageRow, Summary, TableRow, TodoRow, sortMissingPagesForDisplay, summary, tableRows)

import Dict exposing (Dict)
import Page
import PageBacklinks
import PageLinkRefs
import PageTodos
import Set
import Wiki


type alias TodoRow =
    { pageSlug : Page.Slug
    , todoText : String
    }


type alias MissingPageRow =
    { missingPageSlug : Page.Slug
    , linkedFromPageSlugs : List Page.Slug
    }


type alias Summary =
    { todos : List TodoRow
    , missingPages : List MissingPageRow
    }


{-| One row in wiki /todos table: either a {TODO:…} from a page or a missing [[link]] target.
-}
type alias TableRow =
    { itemText : String
    , usedInPageSlugs : List Page.Slug
    , maybeTodoText : Maybe String
    , maybeMissingPageSlug : Maybe Page.Slug
    }


{-| Order for wiki TODOs table: more in-links first; then lexicographic order of
sorted linker slugs (case-insensitive); then missing page slug (case-insensitive).
-}
sortMissingPagesForDisplay : List MissingPageRow -> List MissingPageRow
sortMissingPagesForDisplay rows =
    List.sortBy
        (\row ->
            ( negate (List.length row.linkedFromPageSlugs)
            , row.linkedFromPageSlugs
                |> List.sortBy String.toLower
            , String.toLower row.missingPageSlug
            )
        )
        rows


summary : Wiki.Slug -> Dict Page.Slug String -> Summary
summary wikiSlug publishedPageMarkdownSources =
    { todos = todoRows publishedPageMarkdownSources
    , missingPages = missingPageRows wikiSlug publishedPageMarkdownSources
    }


{-| Pre-sorted list for the wiki TODOs table (missing pages with `sortMissingPagesForDisplay`, then todos).
-}
tableRows : Wiki.Slug -> Dict Page.Slug String -> List TableRow
tableRows wikiSlug publishedPageMarkdownSources =
    let
        todoSummary : Summary
        todoSummary =
            summary wikiSlug publishedPageMarkdownSources
    in
    List.concat
        [ todoSummary.missingPages
            |> sortMissingPagesForDisplay
            |> List.map
                (\row ->
                    { itemText = row.missingPageSlug
                    , usedInPageSlugs = row.linkedFromPageSlugs
                    , maybeTodoText = Nothing
                    , maybeMissingPageSlug = Just row.missingPageSlug
                    }
                )
        , todoSummary.todos
            |> List.map
                (\row ->
                    { itemText = row.todoText
                    , usedInPageSlugs = [ row.pageSlug ]
                    , maybeTodoText = Just row.todoText
                    , maybeMissingPageSlug = Nothing
                    }
                )
        ]


todoRows : Dict Page.Slug String -> List TodoRow
todoRows publishedPageMarkdownSources =
    publishedPageMarkdownSources
        |> Dict.toList
        |> List.concatMap
            (\( pageSlug, markdown ) ->
                PageTodos.todoTexts markdown
                    |> List.map
                        (\todoText ->
                            { pageSlug = pageSlug
                            , todoText = todoText
                            }
                        )
            )


missingPageRows : Wiki.Slug -> Dict Page.Slug String -> List MissingPageRow
missingPageRows wikiSlug publishedPageMarkdownSources =
    let
        publishedSlugSet : Set.Set String
        publishedSlugSet =
            publishedPageMarkdownSources
                |> Dict.keys
                |> List.map String.toLower
                |> Set.fromList

        publishedPages : Dict Page.Slug Page.Page
        publishedPages =
            publishedPageMarkdownSources
                |> Dict.map Page.withPublished

        canonicalMissingSlugs : Dict String Page.Slug
        canonicalMissingSlugs =
            publishedPageMarkdownSources
                |> Dict.toList
                |> List.concatMap (\( _, markdown ) -> PageLinkRefs.linkedPageSlugs wikiSlug markdown)
                |> List.sortBy String.toLower
                |> List.foldl
                    (\linkedSlug acc ->
                        let
                            normalized : String
                            normalized =
                                String.toLower linkedSlug
                        in
                        if Set.member normalized publishedSlugSet || Dict.member normalized acc then
                            acc

                        else
                            Dict.insert normalized linkedSlug acc
                    )
                    Dict.empty
    in
    canonicalMissingSlugs
        |> Dict.values
        |> List.sortBy String.toLower
        |> List.map
            (\missingPageSlug ->
                { missingPageSlug = missingPageSlug
                , linkedFromPageSlugs =
                    PageBacklinks.slugsPointingTo wikiSlug missingPageSlug publishedPages
                }
            )
