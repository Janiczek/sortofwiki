module WikiTodos exposing (MissingPageRow, Summary, TodoRow, summary)

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


summary : Wiki.Slug -> Dict Page.Slug String -> Summary
summary wikiSlug publishedPageMarkdownSources =
    { todos = todoRows publishedPageMarkdownSources
    , missingPages = missingPageRows wikiSlug publishedPageMarkdownSources
    }


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
