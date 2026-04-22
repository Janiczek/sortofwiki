module PageGraph exposing (Edge, EdgeKind(..), Summary, dot, summary)

import Dict exposing (Dict)
import Page
import PageLinkRefs
import Set
import Wiki


type alias Edge =
    { fromPageSlug : Page.Slug
    , toPageSlug : Page.Slug
    , targetPublished : Bool
    , kind : EdgeKind
    }


type EdgeKind
    = WikiLinkEdge
    | TagEdge


type alias Summary =
    { targetPageSlug : Page.Slug
    , backlinkPageSlugs : List Page.Slug
    , outgoingPageSlugs : List Page.Slug
    , missingPageSlugs : List Page.Slug
    , edges : List Edge
    }


summary : Wiki.Slug -> Page.Slug -> Dict Page.Slug String -> Dict Page.Slug (List Page.Slug) -> Summary
summary wikiSlug targetPageSlug publishedPageMarkdownSources publishedPageTags =
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
                        , kind = WikiLinkEdge
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
                        , kind = WikiLinkEdge
                        }
                    )

        targetTagSlugs : List Page.Slug
        targetTagSlugs =
            publishedPageTags
                |> Dict.get targetPageSlug
                |> Maybe.withDefault []
                |> List.sortBy String.toLower

        targetTagEdges : List Edge
        targetTagEdges =
            targetTagSlugs
                |> List.map
                    (\tagSlug ->
                        { fromPageSlug = targetPageSlug
                        , toPageSlug = tagSlug
                        , targetPublished = Set.member (String.toLower tagSlug) publishedSlugSet
                        , kind = TagEdge
                        }
                    )

        pagesTaggingTarget : List Page.Slug
        pagesTaggingTarget =
            publishedPageTags
                |> Dict.toList
                |> List.filterMap
                    (\( sourceSlug, tags ) ->
                        if String.toLower sourceSlug == normalizedTarget then
                            Nothing

                        else if List.any (\tag -> String.toLower tag == normalizedTarget) tags then
                            Just sourceSlug

                        else
                            Nothing
                    )
                |> List.sortBy String.toLower

        incomingTagEdges : List Edge
        incomingTagEdges =
            pagesTaggingTarget
                |> List.map
                    (\sourceSlug ->
                        { fromPageSlug = sourceSlug
                        , toPageSlug = targetPageSlug
                        , targetPublished = True
                        , kind = TagEdge
                        }
                    )

        edges : List Edge
        edges =
            List.concat [ backlinkEdges, outgoingEdges, incomingTagEdges, targetTagEdges ]

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


dot : Wiki.Slug -> Page.Slug -> Dict Page.Slug String -> Dict Page.Slug (List Page.Slug) -> String
dot wikiSlug targetPageSlug publishedPageMarkdownSources publishedPageTags =
    let
        graphSummary : Summary
        graphSummary =
            summary wikiSlug targetPageSlug publishedPageMarkdownSources publishedPageTags

        targetPublished : Bool
        targetPublished =
            Dict.keys publishedPageMarkdownSources
                |> List.any (\slug -> String.toLower slug == String.toLower graphSummary.targetPageSlug)

        targetNodeLine : String
        targetNodeLine =
            "  "
                ++ dotString graphSummary.targetPageSlug
                ++ " [href="
                ++ dotString (Wiki.pageGraphUrlPath wikiSlug graphSummary.targetPageSlug)
                ++ (if targetPublished then
                        ", penwidth=2];"

                    else
                        ", penwidth=2, style="
                            ++ dotString "dashed"
                            ++ ", color="
                            ++ dotString "#dc2626"
                            ++ ", fontcolor="
                            ++ dotString "#dc2626"
                            ++ "];"
                   )

        publishedNodeLine : Page.Slug -> String
        publishedNodeLine pageSlug =
            "  "
                ++ dotString pageSlug
                ++ " [href="
                ++ dotString (Wiki.pageGraphUrlPath wikiSlug pageSlug)
                ++ "];"

        missingNodeLine : Page.Slug -> String
        missingNodeLine pageSlug =
            "  "
                ++ dotString pageSlug
                ++ " [href="
                ++ dotString (Wiki.pageGraphUrlPath wikiSlug pageSlug)
                ++ ", style="
                ++ dotString "dashed"
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
                ++ (case edge.kind of
                        WikiLinkEdge ->
                            ";"

                        TagEdge ->
                            " [style="
                                ++ dotString "dashed"
                                ++ ", color="
                                ++ dotString "#7c3aed"
                                ++ "];"
                   )

        linkedPublishedNodes : List Page.Slug
        linkedPublishedNodes =
            graphSummary.edges
                |> List.concatMap (\edge -> [ edge.fromPageSlug, edge.toPageSlug ])
                |> List.filter (\slug -> List.member (String.toLower slug) (Dict.keys publishedPageMarkdownSources |> List.map String.toLower))
                |> List.filter (\slug -> String.toLower slug /= String.toLower graphSummary.targetPageSlug)
                |> List.foldl
                    (\slug acc ->
                        if List.any (\seen -> String.toLower seen == String.toLower slug) acc then
                            acc

                        else
                            slug :: acc
                    )
                    []
                |> List.sortBy String.toLower
    in
    String.join "\n"
        (List.concat
            [ [ "digraph page {"
              , "  rankdir=LR;"
              , "  graph [pad="
                    ++ dotString "0.1"
                    ++ ", nodesep="
                    ++ dotString "0.2"
                    ++ ", ranksep="
                    ++ dotString "0.35"
                    ++ "];"
              , "  node [shape=box"
                    ++ ", fontname="
                    ++ dotString "'Source Serif 4', system-ui, sans-serif"
                    ++ ", fontsize="
                    ++ dotString "12"
                    ++ ", margin="
                    ++ dotString "0.2,0.04"
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
