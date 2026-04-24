module PageGraphTest exposing (suite)

import Dict
import Expect
import Fuzzers
import Page
import PageGraph
import Test exposing (Test)


suite : Test
suite =
    Test.describe "PageGraph"
        [ Test.describe "summary"
            [ Test.test "collects immediate backlinks and outgoing links" <|
                \() ->
                    PageGraph.summary "Demo"
                        "Home"
                        (Dict.fromList
                            [ ( "Home", "[[About]]\n[[TodoGap]]" )
                            , ( "Guide", "[[Home]]" )
                            , ( "About", "" )
                            ]
                        )
                        (Dict.fromList
                            [ ( "Home", [ "Meta" ] )
                            , ( "Guide", [ "Home" ] )
                            , ( "About", [] )
                            ]
                        )
                        |> Expect.equal
                            { targetPageSlug = "Home"
                            , backlinkPageSlugs = [ "Guide" ]
                            , outgoingPageSlugs = [ "About", "TodoGap" ]
                            , missingPageSlugs = [ "Meta", "TodoGap" ]
                            , edges =
                                [ { fromPageSlug = "Guide", toPageSlug = "Home", direction = PageGraph.Directed, targetPublished = True, kind = PageGraph.WikiLinkEdge }
                                , { fromPageSlug = "Home", toPageSlug = "About", direction = PageGraph.Directed, targetPublished = True, kind = PageGraph.WikiLinkEdge }
                                , { fromPageSlug = "Home", toPageSlug = "TodoGap", direction = PageGraph.Directed, targetPublished = False, kind = PageGraph.WikiLinkEdge }
                                , { fromPageSlug = "Guide", toPageSlug = "Home", direction = PageGraph.Directed, targetPublished = True, kind = PageGraph.TagEdge }
                                , { fromPageSlug = "Home", toPageSlug = "Meta", direction = PageGraph.Directed, targetPublished = False, kind = PageGraph.TagEdge }
                                ]
                            }
            , Test.test "shows reciprocal page links undirected while one-way tags stay directed" <|
                \() ->
                    PageGraph.summary "Demo"
                        "A"
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
                            [ { fromPageSlug = "A", toPageSlug = "B", direction = PageGraph.Undirected, targetPublished = True, kind = PageGraph.WikiLinkEdge }
                            , { fromPageSlug = "A", toPageSlug = "B", direction = PageGraph.Directed, targetPublished = True, kind = PageGraph.TagEdge }
                            ]
            , Test.test "shows one-way page links directed while reciprocal tags become undirected" <|
                \() ->
                    PageGraph.summary "Demo"
                        "A"
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
                            [ { fromPageSlug = "A", toPageSlug = "B", direction = PageGraph.Directed, targetPublished = True, kind = PageGraph.WikiLinkEdge }
                            , { fromPageSlug = "A", toPageSlug = "B", direction = PageGraph.Undirected, targetPublished = True, kind = PageGraph.TagEdge }
                            ]
            , Test.test "shows reciprocal page links and reciprocal tags as two undirected edges" <|
                \() ->
                    PageGraph.summary "Demo"
                        "A"
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
                            [ { fromPageSlug = "A", toPageSlug = "B", direction = PageGraph.Undirected, targetPublished = True, kind = PageGraph.WikiLinkEdge }
                            , { fromPageSlug = "A", toPageSlug = "B", direction = PageGraph.Undirected, targetPublished = True, kind = PageGraph.TagEdge }
                            ]
            , Test.fuzz Fuzzers.graphPairRelations "collapses reciprocal same-kind pairs around focused page without hiding one-way relationships" <|
                \relations ->
                    let
                        graphSummary : PageGraph.Summary
                        graphSummary =
                            PageGraph.summary "Demo"
                                "A"
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
                            pairEdges PageGraph.WikiLinkEdge graphSummary.edges
                                |> Expect.equal (expectedPairEdges PageGraph.WikiLinkEdge relations.leftToRightPageLink relations.rightToLeftPageLink)
                        , \() ->
                            pairEdges PageGraph.TagEdge graphSummary.edges
                                |> Expect.equal (expectedPairEdges PageGraph.TagEdge relations.leftToRightTag relations.rightToLeftTag)
                        ]
                        ()
            , Test.fuzz Fuzzers.pageGraphNeighborhood "includes visible inbound and outbound neighbors for both page links and tags" <|
                \neighborhood ->
                    let
                        graphSummary : PageGraph.Summary
                        graphSummary =
                            PageGraph.summary "Demo"
                                "Target"
                                (Dict.fromList
                                    [ ( "Target", markdownFromTargets neighborhood.outgoingPageLink "OutgoingPage" )
                                    , ( "IncomingPage", markdownFromTargets neighborhood.incomingPageLink "Target" )
                                    , ( "OutgoingPage", "" )
                                    , ( "IncomingTag", "" )
                                    , ( "OutgoingTag", "" )
                                    ]
                                )
                                (Dict.fromList
                                    [ ( "Target", tagsFromTargets neighborhood.outgoingTag "OutgoingTag" )
                                    , ( "IncomingTag", tagsFromTargets neighborhood.incomingTag "Target" )
                                    , ( "IncomingPage", [] )
                                    , ( "OutgoingPage", [] )
                                    , ( "OutgoingTag", [] )
                                    ]
                                )
                    in
                    Expect.all
                        [ \() ->
                            graphSummary.outgoingPageSlugs
                                |> Expect.equal
                                    (if neighborhood.outgoingPageLink then
                                        [ "OutgoingPage" ]

                                     else
                                        []
                                    )
                        , \() ->
                            graphSummary.backlinkPageSlugs
                                |> Expect.equal
                                    (if neighborhood.incomingPageLink then
                                        [ "IncomingPage" ]

                                     else
                                        []
                                    )
                        , \() ->
                            edgeVisible PageGraph.WikiLinkEdge "Target" "OutgoingPage" graphSummary.edges
                                |> Expect.equal neighborhood.outgoingPageLink
                        , \() ->
                            edgeVisible PageGraph.WikiLinkEdge "IncomingPage" "Target" graphSummary.edges
                                |> Expect.equal neighborhood.incomingPageLink
                        , \() ->
                            edgeVisible PageGraph.TagEdge "Target" "OutgoingTag" graphSummary.edges
                                |> Expect.equal neighborhood.outgoingTag
                        , \() ->
                            edgeVisible PageGraph.TagEdge "IncomingTag" "Target" graphSummary.edges
                                |> Expect.equal neighborhood.incomingTag
                        ]
                        ()
            ]
        , Test.describe "dot"
            [ Test.test "renders target, immediate neighbors, and edges" <|
                \() ->
                    let
                        graphDot : String
                        graphDot =
                            PageGraph.dot "Demo"
                                "Home"
                                (Dict.fromList
                                    [ ( "Home", "[[About]]\n[[TodoGap]]" )
                                    , ( "Guide", "[[Home]]" )
                                    , ( "About", "" )
                                    ]
                                )
                                (Dict.fromList
                                    [ ( "Home", [ "Meta" ] )
                                    , ( "Guide", [ "Home" ] )
                                    , ( "About", [] )
                                    ]
                                )
                    in
                    [ String.contains "\"Home\" [href=\"/w/Demo/p/Home\", penwidth=2];" graphDot
                    , String.contains "\"Guide\" [href=\"/w/Demo/pg/Guide\"];" graphDot
                    , String.contains "\"About\" [href=\"/w/Demo/pg/About\"];" graphDot
                    , String.contains "\"TodoGap\" [href=\"/w/Demo/pg/TodoGap\", style=\"dashed\", color=\"#dc2626\", fontcolor=\"#dc2626\"];" graphDot
                    , String.contains "\"Guide\" -> \"Home\";" graphDot
                    , String.contains "\"Home\" -> \"About\";" graphDot
                    , String.contains "\"Home\" -> \"TodoGap\";" graphDot
                    , String.contains "\"Guide\" -> \"Home\" [style=\"dashed\", color=\"#7c3aed\"];" graphDot
                    , String.contains "\"Home\" -> \"Meta\" [style=\"dashed\", color=\"#7c3aed\"];" graphDot
                    , String.contains "label=" graphDot |> not
                    ]
                        |> List.all identity
                        |> Expect.equal True
            , Test.test "renders undirected reciprocal page-link and tag edges without arrowheads" <|
                \() ->
                    let
                        graphDot : String
                        graphDot =
                            PageGraph.dot "Demo"
                                "A"
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
                    [ String.contains "\"A\" -> \"B\" [dir=none];" graphDot
                    , String.contains "\"A\" -> \"B\" [style=\"dashed\", color=\"#7c3aed\", dir=none];" graphDot
                    ]
                        |> List.all identity
                        |> Expect.equal True
            , Test.test "renders href node for published page reached only via tag edge" <|
                \() ->
                    let
                        graphDot : String
                        graphDot =
                            PageGraph.dot "Demo"
                                "Home"
                                (Dict.fromList
                                    [ ( "Home", "" )
                                    , ( "TagOnly", "" )
                                    ]
                                )
                                (Dict.fromList
                                    [ ( "Home", [ "TagOnly" ] )
                                    , ( "TagOnly", [] )
                                    ]
                                )
                    in
                    String.contains "\"TagOnly\" [href=\"/w/Demo/pg/TagOnly\"];" graphDot
                        |> Expect.equal True
            , Test.test "styles target node red when focused page is missing" <|
                \() ->
                    let
                        graphDot : String
                        graphDot =
                            PageGraph.dot "Demo"
                                "MissingFocus"
                                (Dict.fromList
                                    [ ( "Home", "[[MissingFocus]]" )
                                    ]
                                )
                                (Dict.fromList
                                    [ ( "Home", [] )
                                    ]
                                )
                    in
                    String.contains "\"MissingFocus\" [href=\"/w/Demo/p/MissingFocus\", penwidth=2, style=\"dashed\", color=\"#dc2626\", fontcolor=\"#dc2626\"];" graphDot
                        |> Expect.equal True
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


markdownFromTargets : Bool -> Page.Slug -> String
markdownFromTargets hasPageLink targetPageSlug =
    if hasPageLink then
        "[[" ++ targetPageSlug ++ "]]"

    else
        ""


tagsFromTargets : Bool -> Page.Slug -> List Page.Slug
tagsFromTargets hasTag targetPageSlug =
    if hasTag then
        [ targetPageSlug ]

    else
        []


pairEdges : PageGraph.EdgeKind -> List PageGraph.Edge -> List PageGraph.Edge
pairEdges edgeKind edges =
    edges
        |> List.filter (\edge -> edge.kind == edgeKind)


expectedPairEdges : PageGraph.EdgeKind -> Bool -> Bool -> List PageGraph.Edge
expectedPairEdges edgeKind leftToRight rightToLeft =
    case ( leftToRight, rightToLeft ) of
        ( True, True ) ->
            [ { fromPageSlug = "A", toPageSlug = "B", direction = PageGraph.Undirected, targetPublished = True, kind = edgeKind } ]

        ( True, False ) ->
            [ { fromPageSlug = "A", toPageSlug = "B", direction = PageGraph.Directed, targetPublished = True, kind = edgeKind } ]

        ( False, True ) ->
            [ { fromPageSlug = "B", toPageSlug = "A", direction = PageGraph.Directed, targetPublished = True, kind = edgeKind } ]

        ( False, False ) ->
            []


edgeVisible : PageGraph.EdgeKind -> Page.Slug -> Page.Slug -> List PageGraph.Edge -> Bool
edgeVisible edgeKind fromPageSlug toPageSlug edges =
    edges
        |> List.any
            (\edge ->
                edge.kind
                    == edgeKind
                    && (case edge.direction of
                            PageGraph.Directed ->
                                edge.fromPageSlug == fromPageSlug && edge.toPageSlug == toPageSlug

                            PageGraph.Undirected ->
                                samePair edge fromPageSlug toPageSlug
                       )
            )


samePair : PageGraph.Edge -> Page.Slug -> Page.Slug -> Bool
samePair edge fromPageSlug toPageSlug =
    (edge.fromPageSlug == fromPageSlug && edge.toPageSlug == toPageSlug)
        || (edge.fromPageSlug == toPageSlug && edge.toPageSlug == fromPageSlug)
