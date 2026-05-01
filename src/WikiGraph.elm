module WikiGraph exposing (Edge, EdgeDirection(..), EdgeKind(..), Summary, graph, summary)

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
    { publishedPageSlugs : List Page.Slug
    , missingPageSlugs : List Page.Slug
    , edges : List Edge
    , globalEdgeCounts : Dict String Int
    }


summary : Wiki.Slug -> Dict Page.Slug String -> Dict Page.Slug (List Page.Slug) -> Summary
summary wikiSlug publishedPageMarkdownSources publishedPageTags =
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

        wikiLinkEdges : List Edge
        wikiLinkEdges =
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
                                    , direction = Directed
                                    , targetPublished = Set.member (String.toLower toPageSlug) publishedSlugSet
                                    , kind = WikiLinkEdge
                                    }
                                )
                    )

        tagEdges : List Edge
        tagEdges =
            publishedPageTags
                |> Dict.toList
                |> List.sortBy (Tuple.first >> String.toLower)
                |> List.concatMap
                    (\( fromPageSlug, tags ) ->
                        tags
                            |> List.sortBy String.toLower
                            |> List.map
                                (\toPageSlug ->
                                    { fromPageSlug = fromPageSlug
                                    , toPageSlug = toPageSlug
                                    , direction = Directed
                                    , targetPublished = Set.member (String.toLower toPageSlug) publishedSlugSet
                                    , kind = TagEdge
                                    }
                                )
                    )

        edges : List Edge
        edges =
            List.append wikiLinkEdges tagEdges
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

        globalEdgeCounts : Dict String Int
        globalEdgeCounts =
            GraphData.totalEdgeCountsByNormalizedSlug
                { fromSlug = .fromPageSlug
                , toSlug = .toPageSlug
                }
                (List.append wikiLinkEdges tagEdges)

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
    , globalEdgeCounts = globalEdgeCounts
    }


graph :
    Wiki.Slug
    -> Dict Page.Slug String
    -> Dict Page.Slug (List Page.Slug)
    -> UI.Graph.Graph
graph wikiSlug publishedPageMarkdownSources publishedPageTags =
    let
        graphSummary : Summary
        graphSummary =
            summary wikiSlug publishedPageMarkdownSources publishedPageTags

        nodeAttrs : Page.Slug -> UI.Graph.Node
        nodeAttrs pageSlug =
            let
                inboundCount : Int
                inboundCount =
                    Dict.get (String.toLower pageSlug) graphSummary.globalEdgeCounts
                        |> Maybe.withDefault 0
            in
            { id = pageSlug
            , href = Wiki.pageGraphUrlPath wikiSlug pageSlug
            , inboundCount = inboundCount
            , kind = UI.Graph.NormalNode
            }

        missingNodeAttrs : Page.Slug -> UI.Graph.Node
        missingNodeAttrs pageSlug =
            let
                inboundCount : Int
                inboundCount =
                    Dict.get (String.toLower pageSlug) graphSummary.globalEdgeCounts
                        |> Maybe.withDefault 0
            in
            { id = pageSlug
            , href = Wiki.publishedPageUrlPath wikiSlug pageSlug
            , inboundCount = inboundCount
            , kind = UI.Graph.MissingNode
            }
    in
    { graphName = "wiki"
    , nodes =
        List.map nodeAttrs graphSummary.publishedPageSlugs
            ++ List.map missingNodeAttrs graphSummary.missingPageSlugs
    , edges =
        List.map
            (\edge ->
                { from = edge.fromPageSlug
                , to = edge.toPageSlug
                , direction = toUiDirection edge.direction
                , kind = toUiKind edge.kind
                , deemphasized = False
                }
            )
            graphSummary.edges
    }


kindSortKey : EdgeKind -> String
kindSortKey kind =
    case kind of
        WikiLinkEdge ->
            "0"

        TagEdge ->
            "1"


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
