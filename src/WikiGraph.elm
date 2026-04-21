module WikiGraph exposing (Edge, Summary, dot, summary)

import Dict exposing (Dict)
import Page
import PageLinkRefs
import Set
import Wiki


type alias Edge =
    { fromPageSlug : Page.Slug
    , toPageSlug : Page.Slug
    , targetPublished : Bool
    }


type alias Summary =
    { publishedPageSlugs : List Page.Slug
    , missingPageSlugs : List Page.Slug
    , edges : List Edge
    }


summary : Wiki.Slug -> Dict Page.Slug String -> Summary
summary wikiSlug publishedPageMarkdownSources =
    let
        publishedPageSlugs : List Page.Slug
        publishedPageSlugs =
            publishedPageMarkdownSources
                |> Dict.keys
                |> List.sortBy String.toLower

        publishedSlugSet : Set.Set String
        publishedSlugSet =
            publishedPageSlugs
                |> List.map String.toLower
                |> Set.fromList

        edges : List Edge
        edges =
            publishedPageMarkdownSources
                |> Dict.toList
                |> List.sortBy (Tuple.first >> String.toLower)
                |> List.concatMap
                    (\( fromPageSlug, markdown ) ->
                        PageLinkRefs.linkedPageSlugs wikiSlug markdown
                            |> List.sortBy String.toLower
                            |> List.map
                                (\toPageSlug ->
                                    { fromPageSlug = fromPageSlug
                                    , toPageSlug = toPageSlug
                                    , targetPublished = Set.member (String.toLower toPageSlug) publishedSlugSet
                                    }
                                )
                    )

        missingPageSlugs : List Page.Slug
        missingPageSlugs =
            edges
                |> List.filter (\edge -> not edge.targetPublished)
                |> List.foldl
                    (\edge acc ->
                        let
                            normalized : String
                            normalized =
                                String.toLower edge.toPageSlug
                        in
                        if Dict.member normalized acc then
                            acc

                        else
                            Dict.insert normalized edge.toPageSlug acc
                    )
                    Dict.empty
                |> Dict.values
                |> List.sortBy String.toLower
    in
    { publishedPageSlugs = publishedPageSlugs
    , missingPageSlugs = missingPageSlugs
    , edges = edges
    }


dot : Wiki.Slug -> Dict Page.Slug String -> String
dot wikiSlug publishedPageMarkdownSources =
    let
        graphSummary : Summary
        graphSummary =
            summary wikiSlug publishedPageMarkdownSources

        graphAttrsLine : String
        graphAttrsLine =
            "  graph [label="
                ++ dotString wikiSlug
                ++ ", labelloc=t, pad="
                ++ dotString "0.25"
                ++ ", nodesep="
                ++ dotString "0.4"
                ++ ", ranksep="
                ++ dotString "0.7"
                ++ "];"

        nodeAttrsLine : String
        nodeAttrsLine =
            "  node [shape=box, style="
                ++ dotString "rounded"
                ++ ", fontname="
                ++ dotString "Inter, system-ui, sans-serif"
                ++ "];"

        edgeAttrsLine : String
        edgeAttrsLine =
            "  edge [color=" ++ dotString "#6b7280" ++ "];"

        nodeLine : Page.Slug -> String
        nodeLine pageSlug =
            "  "
                ++ dotString pageSlug
                ++ " [href="
                ++ dotString (Wiki.publishedPageUrlPath wikiSlug pageSlug)
                ++ "];"

        missingNodeLine : Page.Slug -> String
        missingNodeLine pageSlug =
            "  "
                ++ dotString pageSlug
                ++ " [href="
                ++ dotString (Wiki.publishedPageUrlPath wikiSlug pageSlug)
                ++ ", style="
                ++ dotString "rounded,dashed"
                ++ ", color="
                ++ dotString "#dc2626"
                ++ ", fontcolor="
                ++ dotString "#dc2626"
                ++ "];"

        edgeLine : Edge -> String
        edgeLine edge =
            "  "
                ++ dotString edge.fromPageSlug
                ++ " -> "
                ++ dotString edge.toPageSlug
                ++ ";"
    in
    String.join "\n"
        (List.concat
            [ [ "digraph wiki {"
              , "  rankdir=LR;"
              , graphAttrsLine
              , nodeAttrsLine
              , edgeAttrsLine
              ]
            , List.map nodeLine graphSummary.publishedPageSlugs
            , List.map missingNodeLine graphSummary.missingPageSlugs
            , List.map edgeLine graphSummary.edges
            , [ "}" ]
            ]
        )


dotString : String -> String
dotString raw =
    "\""
        ++ (raw
                |> String.replace "\\" "\\\\"
                |> String.replace "\"" "\\\""
                |> String.replace "\n" "\\n"
           )
        ++ "\""
