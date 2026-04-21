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
                        |> Expect.equal
                            { targetPageSlug = "Home"
                            , backlinkPageSlugs = [ "Guide" ]
                            , outgoingPageSlugs = [ "About", "TodoGap" ]
                            , missingPageSlugs = [ "TodoGap" ]
                            , edges =
                                [ { fromPageSlug = "Guide", toPageSlug = "Home", targetPublished = True }
                                , { fromPageSlug = "Home", toPageSlug = "About", targetPublished = True }
                                , { fromPageSlug = "Home", toPageSlug = "TodoGap", targetPublished = False }
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
                    in
                    [ String.contains "\"Home\" [href=\"/w/Demo/p/Home\", penwidth=2];" graphDot
                    , String.contains "\"Guide\" [href=\"/w/Demo/p/Guide\"];" graphDot
                    , String.contains "\"About\" [href=\"/w/Demo/p/About\"];" graphDot
                    , String.contains "\"TodoGap\" [href=\"/w/Demo/p/TodoGap\", style=\"rounded,dashed\", color=\"#dc2626\", fontcolor=\"#dc2626\"];" graphDot
                    , String.contains "\"Guide\" -> \"Home\";" graphDot
                    , String.contains "\"Home\" -> \"About\";" graphDot
                    , String.contains "\"Home\" -> \"TodoGap\";" graphDot
                    ]
                        |> List.all identity
                        |> Expect.equal True
            ]
        ]
