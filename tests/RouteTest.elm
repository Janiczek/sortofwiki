module RouteTest exposing (suite)

import Expect
import Fuzz
import Route
import Test exposing (Test)
import Url


suite : Test
suite =
    Test.describe "Route"
        [ Test.test "empty path is wiki list" <|
            \_ ->
                "https://example.com"
                    |> Url.fromString
                    |> Maybe.map (Route.fromUrl >> Route.isWikiList)
                    |> Expect.equal (Just True)
        , Test.test "slash-only path is wiki list" <|
            \_ ->
                "https://example.com/"
                    |> Url.fromString
                    |> Maybe.map (Route.fromUrl >> Route.isWikiList)
                    |> Expect.equal (Just True)
        , Test.test "non-empty path is not wiki list" <|
            \_ ->
                "https://example.com/w/demo"
                    |> Url.fromString
                    |> Maybe.map (Route.fromUrl >> Route.isWikiList)
                    |> Expect.equal (Just False)
        , Test.fuzz Fuzz.string "NotFound preserves url" <|
            \str ->
                let
                    path : String
                    path =
                        "missing" ++ str

                    urlString : String
                    urlString =
                        "https://example.com/" ++ path
                in
                urlString
                    |> Url.fromString
                    |> Maybe.map
                        (\u ->
                            case Route.fromUrl u of
                                Route.NotFound got ->
                                    got == u

                                Route.WikiList ->
                                    False
                        )
                    |> Expect.equal (Just True)
        ]
