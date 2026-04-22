module PageGraphTest exposing (suite)

import Dict
import Expect
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
                                [ { fromPageSlug = "Guide", toPageSlug = "Home", targetPublished = True, kind = PageGraph.WikiLinkEdge }
                                , { fromPageSlug = "Home", toPageSlug = "About", targetPublished = True, kind = PageGraph.WikiLinkEdge }
                                , { fromPageSlug = "Home", toPageSlug = "TodoGap", targetPublished = False, kind = PageGraph.WikiLinkEdge }
                                , { fromPageSlug = "Guide", toPageSlug = "Home", targetPublished = True, kind = PageGraph.TagEdge }
                                , { fromPageSlug = "Home", toPageSlug = "Meta", targetPublished = False, kind = PageGraph.TagEdge }
                                ]
                            }
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
