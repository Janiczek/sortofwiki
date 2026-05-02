module WikiTodosTest exposing (suite)

import Dict
import Expect
import Test exposing (Test)
import WikiTodos


suite : Test
suite =
    Test.describe "WikiTodos"
        [ Test.describe "summary"
            [ Test.test "aggregates TODO rows and missing page backlinks" <|
                \() ->
                    let
                        summary : WikiTodos.Summary
                        summary =
                            WikiTodos.summary "Demo"
                                (Dict.fromList
                                    [ ( "About", "{TODO: explain roles}\n\n[[TodoGap]]" )
                                    , ( "Guides", "See [[TodoGap]] and {TODO: add examples}" )
                                    ]
                                )
                    in
                    summary
                        |> Expect.equal
                            { todos =
                                [ { pageSlug = "About", todoText = "explain roles" }
                                , { pageSlug = "Guides", todoText = "add examples" }
                                ]
                            , missingPages =
                                [ { missingPageSlug = "TodoGap"
                                  , linkedFromPageSlugs = [ "About", "Guides" ]
                                  }
                                ]
                            }
            , Test.test "does not treat published pages as missing" <|
                \() ->
                    WikiTodos.summary "Demo"
                        (Dict.fromList
                            [ ( "Home", "See [[About]]" )
                            , ( "About", "" )
                            ]
                        )
                        |> .missingPages
                        |> Expect.equal []
            ]
        , Test.describe "tableRows"
            [ Test.test "matches concatenated todos then sorted missing pages" <|
                \() ->
                    let
                        sources =
                            Dict.fromList
                                [ ( "About", "{TODO: explain roles}\n\n[[TodoGap]]" )
                                , ( "Guides", "See [[TodoGap]] and {TODO: add examples}" )
                                ]
                    in
                    WikiTodos.tableRows "Demo" sources
                        |> Expect.equal
                            [ { itemText = "explain roles"
                              , usedInPageSlugs = [ "About" ]
                              , maybeTodoText = Just "explain roles"
                              , maybeMissingPageSlug = Nothing
                              }
                            , { itemText = "add examples"
                              , usedInPageSlugs = [ "Guides" ]
                              , maybeTodoText = Just "add examples"
                              , maybeMissingPageSlug = Nothing
                              }
                            , { itemText = "TodoGap"
                              , usedInPageSlugs = [ "About", "Guides" ]
                              , maybeTodoText = Nothing
                              , maybeMissingPageSlug = Just "TodoGap"
                              }
                            ]
            ]
        , Test.describe "sortMissingPagesForDisplay"
            [ Test.test "more in-links first" <|
                \() ->
                    [ { missingPageSlug = "Low"
                      , linkedFromPageSlugs = [ "A" ]
                      }
                    , { missingPageSlug = "High"
                      , linkedFromPageSlugs = [ "A", "B", "C" ]
                      }
                    ]
                        |> WikiTodos.sortMissingPagesForDisplay
                        |> Expect.equal
                            [ { missingPageSlug = "High"
                              , linkedFromPageSlugs = [ "A", "B", "C" ]
                              }
                            , { missingPageSlug = "Low"
                              , linkedFromPageSlugs = [ "A" ]
                              }
                            ]
            , Test.test "same count orders by sorted linker slugs" <|
                \() ->
                    [ { missingPageSlug = "Z"
                      , linkedFromPageSlugs = [ "M", "A" ]
                      }
                    , { missingPageSlug = "Y"
                      , linkedFromPageSlugs = [ "B", "A" ]
                      }
                    ]
                        |> WikiTodos.sortMissingPagesForDisplay
                        |> Expect.equal
                            [ { missingPageSlug = "Y"
                              , linkedFromPageSlugs = [ "B", "A" ]
                              }
                            , { missingPageSlug = "Z"
                              , linkedFromPageSlugs = [ "M", "A" ]
                              }
                            ]
            , Test.test "same count and linker set orders by missing slug" <|
                \() ->
                    [ { missingPageSlug = "Zebra"
                      , linkedFromPageSlugs = [ "B", "A" ]
                      }
                    , { missingPageSlug = "Alpha"
                      , linkedFromPageSlugs = [ "A", "B" ]
                      }
                    ]
                        |> WikiTodos.sortMissingPagesForDisplay
                        |> Expect.equal
                            [ { missingPageSlug = "Alpha"
                              , linkedFromPageSlugs = [ "A", "B" ]
                              }
                            , { missingPageSlug = "Zebra"
                              , linkedFromPageSlugs = [ "B", "A" ]
                              }
                            ]
            ]
        ]
