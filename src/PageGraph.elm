module PageGraph exposing (Edge, Summary, dot, summary)

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
    { targetPageSlug : Page.Slug
    , backlinkPageSlugs : List Page.Slug
    , outgoingPageSlugs : List Page.Slug
    , missingPageSlugs : List Page.Slug
    , edges : List Edge
    }


summary : Wiki.Slug -> Page.Slug -> Dict Page.Slug String -> Summary
summary wikiSlug targetPageSlug publishedPageMarkdownSources =
    let
        normalizedTarget : String
        normalizedTarget =
            String.toLower targetPageSlug

        publishedSlugSet : Set.Set String
        publishedSlugSet =
            publishedPageMarkdownSources
                |> Dict.keys
                |> List.map String.toLower
                |> Set.fromList

        outgoingPageSlugs : List Page.Slug
        outgoingPageSlugs =
            publishedPageMarkdownSources
                |> Dict.get targetPageSlug
                |> Maybe.withDefault ""
                |> PageLinkRefs.linkedPageSlugs wikiSlug
                |> List.sortBy String.toLower

        backlinkPageSlugs : List Page.Slug
        backlinkPageSlugs =
            publishedPageMarkdownSources
                |> Dict.toList
                |> List.filterMap
                    (\( pageSlug, markdown ) ->
                        if String.toLower pageSlug == normalizedTarget then
                            Nothing

                        else if
                            PageLinkRefs.linkedPageSlugs wikiSlug markdown
                                |> List.any (\linkedSlug -> String.toLower linkedSlug == normalizedTarget)
                        then
                            Just pageSlug

                        else
                            Nothing
                    )
                |> List.sortBy String.toLower

        outgoingEdges : List Edge
        outgoingEdges =
            outgoingPageSlugs
                |> List.map
                    (\outgoingSlug ->
                        { fromPageSlug = targetPageSlug
                        , toPageSlug = outgoingSlug
                        , targetPublished = Set.member (String.toLower outgoingSlug) publishedSlugSet
                        }
                    )

        backlinkEdges : List Edge
        backlinkEdges =
            backlinkPageSlugs
                |> List.map
                    (\backlinkSlug ->
                        { fromPageSlug = backlinkSlug
                        , toPageSlug = targetPageSlug
                        , targetPublished = True
                        }
                    )

        edges : List Edge
        edges =
            List.append backlinkEdges outgoingEdges

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
    { targetPageSlug = targetPageSlug
    , backlinkPageSlugs = backlinkPageSlugs
    , outgoingPageSlugs = outgoingPageSlugs
    , missingPageSlugs = missingPageSlugs
    , edges = edges
    }


dot : Wiki.Slug -> Page.Slug -> Dict Page.Slug String -> String
dot wikiSlug targetPageSlug publishedPageMarkdownSources =
    let
        graphSummary : Summary
        graphSummary =
            summary wikiSlug targetPageSlug publishedPageMarkdownSources

        targetNodeLine : String
        targetNodeLine =
            "  "
                ++ dotString graphSummary.targetPageSlug
                ++ " [href="
                ++ dotString (Wiki.publishedPageUrlPath wikiSlug graphSummary.targetPageSlug)
                ++ ", penwidth=2];"

        publishedNodeLine : Page.Slug -> String
        publishedNodeLine pageSlug =
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

        linkedPublishedNodes : List Page.Slug
        linkedPublishedNodes =
            List.append graphSummary.backlinkPageSlugs graphSummary.outgoingPageSlugs
                |> List.filter (\slug -> List.member (String.toLower slug) (Dict.keys publishedPageMarkdownSources |> List.map String.toLower))
                |> List.filter (\slug -> String.toLower slug /= String.toLower graphSummary.targetPageSlug)
                |> List.sortBy String.toLower
    in
    String.join "\n"
        (List.concat
            [ [ "digraph page {"
              , "  rankdir=LR;"
              , "  graph [label="
                    ++ dotString ("Immediate page graph: " ++ graphSummary.targetPageSlug)
                    ++ ", labelloc=t, pad="
                    ++ dotString "0.25"
                    ++ ", nodesep="
                    ++ dotString "0.4"
                    ++ ", ranksep="
                    ++ dotString "0.7"
                    ++ "];"
              , "  node [shape=box, style="
                    ++ dotString "rounded"
                    ++ ", fontname="
                    ++ dotString "Inter, system-ui, sans-serif"
                    ++ "];"
              , "  edge [color=" ++ dotString "#6b7280" ++ "];"
              , targetNodeLine
              ]
            , List.map publishedNodeLine linkedPublishedNodes
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
