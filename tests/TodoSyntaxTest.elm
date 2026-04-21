module TodoSyntaxTest exposing (suite)

import Expect
import Test exposing (Test)
import TodoSyntax


suite : Test
suite =
    Test.describe "TodoSyntax"
        [ Test.describe "segmentsFromPlainText"
            [ Test.test "splits plain text around TODO marker" <|
                \() ->
                    TodoSyntax.segmentsFromPlainText "Before {TODO: finish docs} after"
                        |> Expect.equal
                            [ TodoSyntax.Plain "Before "
                            , TodoSyntax.Todo "finish docs"
                            , TodoSyntax.Plain " after"
                            ]
            , Test.test "invalid empty TODO marker stays plain text" <|
                \() ->
                    TodoSyntax.segmentsFromPlainText "Broken {TODO:   } marker"
                        |> Expect.equal
                            [ TodoSyntax.Plain "Broken "
                            , TodoSyntax.Plain "{"
                            , TodoSyntax.Plain "TODO:   } marker"
                            ]
            ]
        , Test.describe "todoTextsFromPlainText"
            [ Test.test "collects TODO texts in order" <|
                \() ->
                    TodoSyntax.todoTextsFromPlainText "{TODO: one} and {TODO: two}"
                        |> Expect.equal [ "one", "two" ]
            ]
        ]
