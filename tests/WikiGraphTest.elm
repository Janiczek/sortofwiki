module WikiGraphTest exposing (suite)

import Dict
import Expect
import Fuzz
import Fuzzers
import Page
import PageLinkRefs
import Test exposing (Test)
import UI.Graph
import Wiki
import WikiGraph


suite : Test
suite =
    Test.describe "WikiGraph"
        [ Test.describe "summary"
            [ Test.test "collects published pages, missing pages, and edges" <|
                \() ->
                    WikiGraph.summary "Demo"
                        (Dict.fromList
                            [ ( "About", "[[Home]]\n[[TodoGap]]" )
                            , ( "Home", "[[About]]" )
                            ]
                        )
                        (Dict.fromList
                            [ ( "About", [ "Meta" ] )
                            , ( "Home", [] )
                            ]
                        )
                        |> Expect.equal
                            { publishedPageSlugs = [ "About", "Home" ]
                            , missingPageSlugs = [ "Meta", "TodoGap" ]
                            , edges =
                                [ { fromPageSlug = "About", toPageSlug = "Home", direction = WikiGraph.Undirected, targetPublished = True, kind = WikiGraph.WikiLinkEdge }
                                , { fromPageSlug = "About", toPageSlug = "TodoGap", direction = WikiGraph.Directed, targetPublished = False, kind = WikiGraph.WikiLinkEdge }
                                , { fromPageSlug = "About", toPageSlug = "Meta", direction = WikiGraph.Directed, targetPublished = False, kind = WikiGraph.TagEdge }
                                ]
                            , globalEdgeCounts = Dict.fromList [ ( "about", 4 ), ( "home", 2 ), ( "meta", 1 ), ( "todogap", 1 ) ]
                            }
            , Test.test "keeps reciprocal page links undirected while one-way tags stay directed" <|
                \() ->
                    WikiGraph.summary "Demo"
                        (Dict.fromList
                            [ ( "A", "[[B]]" )
                            , ( "B", "[[A]]" )
                            ]
                        )
                        (Dict.fromList
                            [ ( "A", [ "B" ] )
                            , ( "B", [] )
                            ]
                        )
                        |> .edges
                        |> Expect.equal
                            [ { fromPageSlug = "A", toPageSlug = "B", direction = WikiGraph.Undirected, targetPublished = True, kind = WikiGraph.WikiLinkEdge }
                            , { fromPageSlug = "A", toPageSlug = "B", direction = WikiGraph.Directed, targetPublished = True, kind = WikiGraph.TagEdge }
                            ]
            , Test.test "keeps one-way page links directed while reciprocal tags become undirected" <|
                \() ->
                    WikiGraph.summary "Demo"
                        (Dict.fromList
                            [ ( "A", "[[B]]" )
                            , ( "B", "" )
                            ]
                        )
                        (Dict.fromList
                            [ ( "A", [ "B" ] )
                            , ( "B", [ "A" ] )
                            ]
                        )
                        |> .edges
                        |> Expect.equal
                            [ { fromPageSlug = "A", toPageSlug = "B", direction = WikiGraph.Directed, targetPublished = True, kind = WikiGraph.WikiLinkEdge }
                            , { fromPageSlug = "A", toPageSlug = "B", direction = WikiGraph.Undirected, targetPublished = True, kind = WikiGraph.TagEdge }
                            ]
            , Test.test "renders reciprocal page links and reciprocal tags as two undirected edges" <|
                \() ->
                    WikiGraph.summary "Demo"
                        (Dict.fromList
                            [ ( "A", "[[B]]" )
                            , ( "B", "[[A]]" )
                            ]
                        )
                        (Dict.fromList
                            [ ( "A", [ "B" ] )
                            , ( "B", [ "A" ] )
                            ]
                        )
                        |> .edges
                        |> Expect.equal
                            [ { fromPageSlug = "A", toPageSlug = "B", direction = WikiGraph.Undirected, targetPublished = True, kind = WikiGraph.WikiLinkEdge }
                            , { fromPageSlug = "A", toPageSlug = "B", direction = WikiGraph.Undirected, targetPublished = True, kind = WikiGraph.TagEdge }
                            ]
            , Test.fuzz Fuzzers.graphPairRelations "collapses reciprocal same-kind pairs without hiding one-way relationships" <|
                \relations ->
                    let
                        graphSummary : WikiGraph.Summary
                        graphSummary =
                            WikiGraph.summary "Demo"
                                (Dict.fromList
                                    [ ( "A", pairMarkdown relations.leftToRightPageLink "B" )
                                    , ( "B", pairMarkdown relations.rightToLeftPageLink "A" )
                                    ]
                                )
                                (Dict.fromList
                                    [ ( "A", pairTags relations.leftToRightTag "B" )
                                    , ( "B", pairTags relations.rightToLeftTag "A" )
                                    ]
                                )
                    in
                    Expect.all
                        [ \() ->
                            pairEdges WikiGraph.WikiLinkEdge graphSummary.edges
                                |> Expect.equal (expectedPairEdges WikiGraph.WikiLinkEdge relations.leftToRightPageLink relations.rightToLeftPageLink)
                        , \() ->
                            pairEdges WikiGraph.TagEdge graphSummary.edges
                                |> Expect.equal (expectedPairEdges WikiGraph.TagEdge relations.leftToRightTag relations.rightToLeftTag)
                        ]
                        ()
            , Test.fuzz Fuzzers.graphInput "keeps every wiki-link and tag relationship visible in summary" <|
                \graphInput ->
                    let
                        graphSummary : WikiGraph.Summary
                        graphSummary =
                            WikiGraph.summary "Demo" graphInput.publishedPageMarkdownSources graphInput.publishedPageTags
                    in
                    Expect.all
                        [ \() ->
                            visibleWikiLinkPairs graphInput.publishedPageMarkdownSources
                                |> List.all (\( fromPageSlug, toPageSlug ) -> edgeVisible WikiGraph.WikiLinkEdge fromPageSlug toPageSlug graphSummary.edges)
                                |> Expect.equal True
                        , \() ->
                            visibleTagPairs graphInput.publishedPageTags
                                |> List.all (\( fromPageSlug, toPageSlug ) -> edgeVisible WikiGraph.TagEdge fromPageSlug toPageSlug graphSummary.edges)
                                |> Expect.equal True
                        ]
                        ()
            ]
        , Test.describe "graph"
            [ Test.test "renders published nodes, missing nodes, and edges" <|
                \() ->
                    let
                        renderedGraph : UI.Graph.Graph
                        renderedGraph =
                            WikiGraph.graph "Demo"
                                (Dict.fromList
                                    [ ( "About", "[[Home]]\n[[TodoGap]]" )
                                    , ( "Home", "[[About]]" )
                                    ]
                                )
                                (Dict.fromList
                                    [ ( "About", [ "Meta" ] )
                                    , ( "Home", [] )
                                    ]
                                )
                    in
                    [ renderedGraph.nodes
                        |> List.any (\node -> node.id == "About" && node.href == "/w/Demo/pg/About" && node.kind == UI.Graph.NormalNode)
                    , renderedGraph.nodes
                        |> List.any (\node -> node.id == "Home" && node.href == "/w/Demo/pg/Home" && node.kind == UI.Graph.NormalNode)
                    , renderedGraph.nodes
                        |> List.any (\node -> node.id == "TodoGap" && node.href == "/w/Demo/p/TodoGap" && node.kind == UI.Graph.MissingNode)
                    , renderedGraph.edges
                        |> List.any (\edge -> edge.from == "About" && edge.to == "Home" && edge.direction == UI.Graph.Undirected && edge.kind == UI.Graph.LinkEdge)
                    , renderedGraph.edges
                        |> List.any (\edge -> edge.from == "About" && edge.to == "TodoGap" && edge.direction == UI.Graph.Directed && edge.kind == UI.Graph.LinkEdge)
                    , renderedGraph.edges
                        |> List.any (\edge -> edge.from == "About" && edge.to == "Meta" && edge.direction == UI.Graph.Directed && edge.kind == UI.Graph.TagEdge)
                    ]
                        |> List.all identity
                        |> Expect.equal True
            , Test.test "renders undirected reciprocal page-link and tag edges" <|
                \() ->
                    let
                        renderedGraph : UI.Graph.Graph
                        renderedGraph =
                            WikiGraph.graph "Demo"
                                (Dict.fromList
                                    [ ( "A", "[[B]]" )
                                    , ( "B", "[[A]]" )
                                    ]
                                )
                                (Dict.fromList
                                    [ ( "A", [ "B" ] )
                                    , ( "B", [ "A" ] )
                                    ]
                                )
                    in
                    [ renderedGraph.edges
                        |> List.any (\edge -> edge.from == "A" && edge.to == "B" && edge.direction == UI.Graph.Undirected && edge.kind == UI.Graph.LinkEdge)
                    , renderedGraph.edges
                        |> List.any (\edge -> edge.from == "A" && edge.to == "B" && edge.direction == UI.Graph.Undirected && edge.kind == UI.Graph.TagEdge)
                    ]
                        |> List.all identity
                        |> Expect.equal True
            , Test.fuzz (Fuzz.map2 Tuple.pair Fuzzers.wikiSlug Fuzzers.pageSlug) "includes href for each published page node" <|
                \( wikiSlug, pageSlug ) ->
                    WikiGraph.graph wikiSlug (Dict.fromList [ ( pageSlug, "" ) ]) (Dict.fromList [ ( pageSlug, [] ) ])
                        |> .nodes
                        |> List.any (\node -> node.id == pageSlug && node.href == Wiki.pageGraphUrlPath wikiSlug pageSlug)
                        |> Expect.equal True
            ]
        , Test.describe "directedInOutCountsBySlug"
            [ Test.test "counts wiki link and tag to same target as separate in/out edges" <|
                \() ->
                    WikiGraph.directedInOutCountsBySlug "Demo"
                        (Dict.fromList [ ( "A", "[[B]]" ) ])
                        (Dict.fromList [ ( "A", [ "B" ] ) ])
                        |> Expect.equal
                            { inByNormalizedTarget = Dict.fromList [ ( "b", 2 ) ]
                            , outByNormalizedSource = Dict.fromList [ ( "a", 2 ) ]
                            }
            , Test.test "self wiki link and self tag each bump in and out once" <|
                \() ->
                    WikiGraph.directedInOutCountsBySlug "Demo"
                        (Dict.fromList [ ( "A", "[[A]]" ) ])
                        (Dict.fromList [ ( "A", [ "A" ] ) ])
                        |> Expect.equal
                            { inByNormalizedTarget = Dict.fromList [ ( "a", 2 ) ]
                            , outByNormalizedSource = Dict.fromList [ ( "a", 2 ) ]
                            }
            ]
        ]


pairMarkdown : Bool -> Page.Slug -> String
pairMarkdown hasPageLink targetPageSlug =
    if hasPageLink then
        "[[" ++ targetPageSlug ++ "]]"

    else
        ""


pairTags : Bool -> Page.Slug -> List Page.Slug
pairTags hasTag targetPageSlug =
    if hasTag then
        [ targetPageSlug ]

    else
        []


pairEdges : WikiGraph.EdgeKind -> List WikiGraph.Edge -> List WikiGraph.Edge
pairEdges edgeKind edges =
    edges
        |> List.filter (\edge -> edge.kind == edgeKind)


expectedPairEdges : WikiGraph.EdgeKind -> Bool -> Bool -> List WikiGraph.Edge
expectedPairEdges edgeKind leftToRight rightToLeft =
    case ( leftToRight, rightToLeft ) of
        ( True, True ) ->
            [ { fromPageSlug = "A", toPageSlug = "B", direction = WikiGraph.Undirected, targetPublished = True, kind = edgeKind } ]

        ( True, False ) ->
            [ { fromPageSlug = "A", toPageSlug = "B", direction = WikiGraph.Directed, targetPublished = True, kind = edgeKind } ]

        ( False, True ) ->
            [ { fromPageSlug = "B", toPageSlug = "A", direction = WikiGraph.Directed, targetPublished = True, kind = edgeKind } ]

        ( False, False ) ->
            []


visibleWikiLinkPairs : Dict.Dict Page.Slug String -> List ( Page.Slug, Page.Slug )
visibleWikiLinkPairs publishedPageMarkdownSources =
    publishedPageMarkdownSources
        |> Dict.toList
        |> List.concatMap
            (\( fromPageSlug, markdown ) ->
                PageLinkRefs.linkedPageSlugs "Demo" markdown
                    |> List.map (\toPageSlug -> ( fromPageSlug, toPageSlug ))
            )


visibleTagPairs : Dict.Dict Page.Slug (List Page.Slug) -> List ( Page.Slug, Page.Slug )
visibleTagPairs publishedPageTags =
    publishedPageTags
        |> Dict.toList
        |> List.concatMap
            (\( fromPageSlug, tagSlugs ) ->
                tagSlugs
                    |> List.map (\toPageSlug -> ( fromPageSlug, toPageSlug ))
            )


edgeVisible : WikiGraph.EdgeKind -> Page.Slug -> Page.Slug -> List WikiGraph.Edge -> Bool
edgeVisible edgeKind fromPageSlug toPageSlug edges =
    edges
        |> List.any
            (\edge ->
                edge.kind
                    == edgeKind
                    && (case edge.direction of
                            WikiGraph.Directed ->
                                edge.fromPageSlug == fromPageSlug && edge.toPageSlug == toPageSlug

                            WikiGraph.Undirected ->
                                samePair edge fromPageSlug toPageSlug
                       )
            )


samePair : WikiGraph.Edge -> Page.Slug -> Page.Slug -> Bool
samePair edge fromPageSlug toPageSlug =
    (edge.fromPageSlug == fromPageSlug && edge.toPageSlug == toPageSlug)
        || (edge.fromPageSlug == toPageSlug && edge.toPageSlug == fromPageSlug)
