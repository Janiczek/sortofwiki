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
        ]
