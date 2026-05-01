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
            , Test.test "matches prefix variants of indexed words" <|
                \() ->
                    let
                        pages : Dict.Dict String String
                        pages =
                            Dict.fromList
                                [ ( "Docs", "setting" )
                                ]

                        slugsFor : String -> List String
                        slugsFor query =
                            WikiSearch.search query pages
                                |> List.map .pageSlug
                    in
                    [ "set", "sett", "setti", "settin", "setting" ]
                        |> List.map slugsFor
                        |> Expect.equal
                            [ [ "Docs" ]
                            , [ "Docs" ]
                            , [ "Docs" ]
                            , [ "Docs" ]
                            , [ "Docs" ]
                            ]
            , Test.test "indexes wiki link target and label words" <|
                \() ->
                    let
                        pages : Dict.Dict String String
                        pages =
                            Dict.fromList
                                [ ( "Docs", "[[FooBar|xyz abc]]" )
                                ]

                        slugsFor : String -> List String
                        slugsFor query =
                            WikiSearch.search query pages
                                |> List.map .pageSlug
                    in
                    [ "foobar", "xyz", "abc" ]
                        |> List.map slugsFor
                        |> Expect.equal
                            [ [ "Docs" ]
                            , [ "Docs" ]
                            , [ "Docs" ]
                            ]
            , Test.test "matches insight from SurvivalSkill markdown link label" <|
                \() ->
                    WikiSearch.search "insight"
                        (Dict.fromList
                            [ ( "SurvivalSkill"
                              , "# Survival (skill)\n\nBeing able to survive in various situations. Getting out of harm's way. The level of detail of one's perception.\n\n* [[Outdoorsmanship|outdoorsmanship]]\n* [[Sneaking|sneaking]]\n* [[Insight|insight]] when in conversation or examining an area or an object\n* [[Cartography|cartography]]\n* [[Tracking|tracking]]\n* [[AnimalHandling|animal handling]]\n* [[Scavenging|scavenging]]\n\n{TODO: List synergies here too}"
                              )
                            ]
                        )
                        |> List.map .pageSlug
                        |> Expect.equal [ "SurvivalSkill" ]
            ]
        ]
