module WikiSearchTest exposing (suite)

import Dict
import Expect
import Test exposing (Test)
import WikiSearch


suite : Test
suite =
    Test.describe "WikiSearch"
        [ Test.describe "search"
            [ Test.test "matches page slug even when markdown does not include query" <|
                \() ->
                    let
                        results : List WikiSearch.ResultItem
                        results =
                            WikiSearch.search "Roadmap"
                                (Dict.fromList
                                    [ ( "Roadmap", "Planning notes only." )
                                    , ( "Alpha", "Unrelated body" )
                                    ]
                                )
                    in
                    results
                        |> List.map .pageSlug
                        |> Expect.equal [ "Roadmap" ]
            , Test.test "returns no results for empty query" <|
                \() ->
                    WikiSearch.search "   "
                        (Dict.fromList [ ( "Home", "hello" ) ])
                        |> Expect.equal []
            , Test.test "matches markdown body terms" <|
                \() ->
                    let
                        results : List WikiSearch.ResultItem
                        results =
                            WikiSearch.search "banana"
                                (Dict.fromList
                                    [ ( "Fruits", "Apple and banana and pear." )
                                    , ( "Vehicles", "Car and bus." )
                                    ]
                                )
                    in
                    results
                        |> List.map .pageSlug
                        |> Expect.equal [ "Fruits" ]
            ]
        ]
