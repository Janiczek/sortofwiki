module PageGraph exposing (Edge, EdgeDirection(..), EdgeKind(..), Summary, graph, summary)

import Dict exposing (Dict)
import GraphData
import Page
import PageLinkRefs
import Set
import UI.Graph
import Wiki


type alias Edge =
    { fromPageSlug : Page.Slug
    , toPageSlug : Page.Slug
    , direction : EdgeDirection
    , targetPublished : Bool
    , kind : EdgeKind
    }


type EdgeDirection
    = Directed
    | Undirected


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
                        , direction = Directed
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
                        , direction = Directed
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
                        , direction = Directed
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
                        , direction = Directed
                        , targetPublished = True
                        , kind = TagEdge
                        }
                    )

        edges : List Edge
        edges =
            List.concat [ backlinkEdges, outgoingEdges, incomingTagEdges, targetTagEdges ]
                |> GraphData.normalizeEdges
                    { fromSlug = .fromPageSlug
                    , toSlug = .toPageSlug
                    , direction = .direction >> toGraphDataDirection
                    , kindSortKey = .kind >> kindSortKey
                    , toUndirected =
                        \pair edge ->
                            { fromPageSlug = pair.canonicalFrom
                            , toPageSlug = pair.canonicalTo
                            , direction = Undirected
                            , targetPublished = True
                            , kind = edge.kind
                            }
                    }

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


graph :
    Wiki.Slug
    -> Page.Slug
    -> Dict Page.Slug String
    -> Dict Page.Slug (List Page.Slug)
    -> UI.Graph.Graph
graph wikiSlug targetPageSlug publishedPageMarkdownSources publishedPageTags =
    let
        graphSummary : Summary
        graphSummary =
            summary wikiSlug targetPageSlug publishedPageMarkdownSources publishedPageTags

        globalEdgeCounts : Dict String Int
        globalEdgeCounts =
            List.append
                (edgesFromMarkdown wikiSlug publishedPageMarkdownSources)
                (edgesFromTags publishedPageTags)
                |> GraphData.totalEdgeCountsByNormalizedSlug
                    { fromSlug = .fromPageSlug
                    , toSlug = .toPageSlug
                    }

        targetNode : UI.Graph.Node
        targetNode =
            let
                targetPublished : Bool
                targetPublished =
                    Dict.keys publishedPageMarkdownSources
                        |> List.any (\slug -> String.toLower slug == String.toLower graphSummary.targetPageSlug)

                inboundCount : Int
                inboundCount =
                    Dict.get (String.toLower graphSummary.targetPageSlug) globalEdgeCounts
                        |> Maybe.withDefault 0
            in
            { id = graphSummary.targetPageSlug
            , href = Wiki.publishedPageUrlPath wikiSlug graphSummary.targetPageSlug
            , inboundCount = inboundCount
            , kind =
                if targetPublished then
                    UI.Graph.FocusedNode

                else
                    UI.Graph.MissingFocusedNode
            }

        publishedNode : Page.Slug -> UI.Graph.Node
        publishedNode pageSlug =
            let
                inboundCount : Int
                inboundCount =
                    Dict.get (String.toLower pageSlug) globalEdgeCounts
                        |> Maybe.withDefault 0
            in
            { id = pageSlug
            , href = Wiki.pageGraphUrlPath wikiSlug pageSlug
            , inboundCount = inboundCount
            , kind = UI.Graph.NormalNode
            }

        missingNode : Page.Slug -> UI.Graph.Node
        missingNode pageSlug =
            let
                inboundCount : Int
                inboundCount =
                    Dict.get (String.toLower pageSlug) globalEdgeCounts
                        |> Maybe.withDefault 0
            in
            { id = pageSlug
            , href = Wiki.publishedPageUrlPath wikiSlug pageSlug
            , inboundCount = inboundCount
            , kind = UI.Graph.MissingNode
            }

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

        presentNodeSet : Set.Set String
        presentNodeSet =
            List.concat
                [ [ graphSummary.targetPageSlug ]
                , linkedPublishedNodes
                , graphSummary.missingPageSlugs
                ]
                |> List.map String.toLower
                |> Set.fromList

        directEdgeKeys : Set.Set String
        directEdgeKeys =
            graphSummary.edges
                |> List.map edgeKey
                |> Set.fromList

        contextualEdges : List Edge
        contextualEdges =
            List.append
                (edgesFromMarkdown wikiSlug publishedPageMarkdownSources)
                (edgesFromTags publishedPageTags)
                |> GraphData.normalizeEdges
                    { fromSlug = .fromPageSlug
                    , toSlug = .toPageSlug
                    , direction = .direction >> toGraphDataDirection
                    , kindSortKey = .kind >> kindSortKey
                    , toUndirected =
                        \pair edge ->
                            { fromPageSlug = pair.canonicalFrom
                            , toPageSlug = pair.canonicalTo
                            , direction = Undirected
                            , targetPublished = True
                            , kind = edge.kind
                            }
                    }
                |> List.filter
                    (\edge ->
                        Set.member (String.toLower edge.fromPageSlug) presentNodeSet
                            && Set.member (String.toLower edge.toPageSlug) presentNodeSet
                    )
                |> List.filter (\edge -> not (Set.member (edgeKey edge) directEdgeKeys))
    in
    { graphName = "page"
    , nodes =
        List.concat
            [ [ targetNode ]
            , List.map publishedNode linkedPublishedNodes
            , List.map missingNode graphSummary.missingPageSlugs
            ]
    , edges =
        List.append
            (graphSummary.edges
                |> List.map
                    (\edge ->
                        { from = edge.fromPageSlug
                        , to = edge.toPageSlug
                        , direction = toUiDirection edge.direction
                        , kind = toUiKind edge.kind
                        , deemphasized = False
                        }
                    )
            )
            (contextualEdges
                |> List.map
                    (\edge ->
                        { from = edge.fromPageSlug
                        , to = edge.toPageSlug
                        , direction = toUiDirection edge.direction
                        , kind = toUiKind edge.kind
                        , deemphasized = True
                        }
                    )
            )
    }


kindSortKey : EdgeKind -> String
kindSortKey kind =
    case kind of
        WikiLinkEdge ->
            "0"

        TagEdge ->
            "1"


edgesFromMarkdown : Wiki.Slug -> Dict Page.Slug String -> List Edge
edgesFromMarkdown wikiSlug publishedPageMarkdownSources =
    publishedPageMarkdownSources
        |> Dict.toList
        |> List.concatMap
            (\( fromPageSlug, markdown ) ->
                PageLinkRefs.linkedPageSlugs wikiSlug markdown
                    |> List.map
                        (\toPageSlug ->
                            { fromPageSlug = fromPageSlug
                            , toPageSlug = toPageSlug
                            , direction = Directed
                            , targetPublished = True
                            , kind = WikiLinkEdge
                            }
                        )
            )


edgesFromTags : Dict Page.Slug (List Page.Slug) -> List Edge
edgesFromTags publishedPageTags =
    publishedPageTags
        |> Dict.toList
        |> List.concatMap
            (\( fromPageSlug, tags ) ->
                tags
                    |> List.map
                        (\toPageSlug ->
                            { fromPageSlug = fromPageSlug
                            , toPageSlug = toPageSlug
                            , direction = Directed
                            , targetPublished = True
                            , kind = TagEdge
                            }
                        )
            )


toGraphDataDirection : EdgeDirection -> GraphData.EdgeDirection
toGraphDataDirection direction =
    case direction of
        Directed ->
            GraphData.Directed

        Undirected ->
            GraphData.Undirected


toUiDirection : EdgeDirection -> UI.Graph.EdgeDirection
toUiDirection direction =
    case direction of
        Directed ->
            UI.Graph.Directed

        Undirected ->
            UI.Graph.Undirected


toUiKind : EdgeKind -> UI.Graph.EdgeKind
toUiKind kind =
    case kind of
        WikiLinkEdge ->
            UI.Graph.LinkEdge

        TagEdge ->
            UI.Graph.TagEdge


edgeKey : Edge -> String
edgeKey edge =
    String.join "|"
        [ edge.fromPageSlug |> String.toLower
        , edge.toPageSlug |> String.toLower
        , edge.direction |> toGraphDataDirection |> graphDataDirectionKey
        , edge.kind |> kindSortKey
        ]


graphDataDirectionKey : GraphData.EdgeDirection -> String
graphDataDirectionKey direction =
    case direction of
        GraphData.Directed ->
            "directed"

        GraphData.Undirected ->
            "undirected"
