module UILinkTest exposing (suite)

import Expect
import Test exposing (Test)
import UI.Link
import Url exposing (Url)


localhost8000 : Url
localhost8000 =
    Url.fromString "http://localhost:8000/"
        |> Maybe.withDefault
            { protocol = Url.Http
            , host = "localhost"
            , port_ = Just 8000
            , path = "/"
            , query = Nothing
            , fragment = Nothing
            }


suite : Test
suite =
    Test.describe "UI.Link"
        [ Test.describe "outsideHttpAttrs"
            [ Test.test "three attrs for off-site https" <|
                \() ->
                    UI.Link.outsideHttpAttrs localhost8000 "https://example.org/z"
                        |> List.length
                        |> Expect.equal 3
            , Test.test "href only when same origin" <|
                \() ->
                    UI.Link.outsideHttpAttrs localhost8000 "http://localhost:8000/other"
                        |> List.length
                        |> Expect.equal 1
            ]
        ]
