module MarkdownLinkTargetTest exposing (suite)

import Expect
import MarkdownLinkTarget
import Test exposing (Test)
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
    Test.describe "MarkdownLinkTarget"
        [ Test.describe "attrsIfOutsideHttp"
            [ Test.test "no attrs for relative path" <|
                \() ->
                    MarkdownLinkTarget.attrsIfOutsideHttp localhost8000 "/w/Demo/p/Home"
                        |> List.length
                        |> Expect.equal 0
            , Test.test "two attrs for https URL on another host" <|
                \() ->
                    MarkdownLinkTarget.attrsIfOutsideHttp localhost8000 "https://example.org/z"
                        |> List.length
                        |> Expect.equal 2
            , Test.test "no attrs for same-origin absolute URL" <|
                \() ->
                    MarkdownLinkTarget.attrsIfOutsideHttp localhost8000 "http://localhost:8000/other"
                        |> List.length
                        |> Expect.equal 0
            , Test.test "two attrs for protocol-relative URL on another host" <|
                \() ->
                    MarkdownLinkTarget.attrsIfOutsideHttp localhost8000 "//example.org/a"
                        |> List.length
                        |> Expect.equal 2
            ]
        ]
