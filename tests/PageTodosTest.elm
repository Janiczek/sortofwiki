module PageTodosTest exposing (suite)

import Expect
import PageTodos
import Test exposing (Test)


suite : Test
suite =
    Test.describe "PageTodos"
        [ Test.describe "todoTexts"
            [ Test.test "collects TODOs from markdown text flow" <|
                \() ->
                    PageTodos.todoTexts "Intro {TODO: write intro}\n\n- {TODO: add list example}"
                        |> Expect.equal [ "write intro", "add list example" ]
            , Test.test "ignores TODO syntax inside inline code and fenced code" <|
                \() ->
                    PageTodos.todoTexts "Use `{TODO: nope}` here.\n\n```elm\n{TODO: also nope}\n```"
                        |> Expect.equal []
            ]
        ]
