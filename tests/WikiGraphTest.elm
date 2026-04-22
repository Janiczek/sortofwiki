module WikiGraphTest exposing (suite)

import Dict
import Expect
import Fuzz
import Fuzzers
import Test exposing (Test)
import Wiki
import WikiGraph


dotString : String -> String
dotString raw =
    "\""
        ++ (raw
                |> String.replace "\\" "\\\\"
                |> String.replace "\"" "\\\""
                |> String.replace "\n" "\\n"
           )
        ++ "\""


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
                                [ { fromPageSlug = "About", toPageSlug = "Home", targetPublished = True, kind = WikiGraph.WikiLinkEdge }
                                , { fromPageSlug = "About", toPageSlug = "TodoGap", targetPublished = False, kind = WikiGraph.WikiLinkEdge }
                                , { fromPageSlug = "Home", toPageSlug = "About", targetPublished = True, kind = WikiGraph.WikiLinkEdge }
                                , { fromPageSlug = "About", toPageSlug = "Meta", targetPublished = False, kind = WikiGraph.TagEdge }
                                ]
                            }
            ]
        , Test.describe "dot"
            [ Test.test "renders published nodes, missing nodes, and edges" <|
                \() ->
                    let
                        graphDot : String
                        graphDot =
                            WikiGraph.dot "Demo"
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
                    [ String.contains "\"About\" [href=\"/w/Demo/pg/About\"];" graphDot
                    , String.contains "\"Home\" [href=\"/w/Demo/pg/Home\"];" graphDot
                    , String.contains "\"TodoGap\" [href=\"/w/Demo/pg/TodoGap\", style=\"rounded,dashed\", color=\"#dc2626\", fontcolor=\"#dc2626\"];" graphDot
                    , String.contains "\"About\" -> \"Home\";" graphDot
                    , String.contains "\"About\" -> \"TodoGap\";" graphDot
                    , String.contains "\"Home\" -> \"About\";" graphDot
                    , String.contains "\"About\" -> \"Meta\" [style=\"dashed\", color=\"#7c3aed\"];" graphDot
                    , String.contains "label=" graphDot |> not
                    ]
                        |> List.all identity
                        |> Expect.equal True
            , Test.fuzz (Fuzz.map2 Tuple.pair Fuzzers.wikiSlug Fuzzers.pageSlug) "includes href for each published page node" <|
                \( wikiSlug, pageSlug ) ->
                    WikiGraph.dot wikiSlug (Dict.fromList [ ( pageSlug, "" ) ]) (Dict.fromList [ ( pageSlug, [] ) ])
                        |> String.contains (dotString (Wiki.pageGraphUrlPath wikiSlug pageSlug))
                        |> Expect.equal True
            ]
        ]
