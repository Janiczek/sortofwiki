module RouteTest exposing (suite)

import Expect
import Fuzz
import Fuzzers
import Route
import Store
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
        , Test.test "wiki home path is not wiki list" <|
            \_ ->
                "https://example.com/w/demo"
                    |> Url.fromString
                    |> Maybe.map (Route.fromUrl >> Route.isWikiList)
                    |> Expect.equal (Just False)
        , Test.test "/w/demo is WikiHome demo" <|
            \_ ->
                "https://example.com/w/demo"
                    |> Url.fromString
                    |> Maybe.map Route.fromUrl
                    |> Expect.equal (Just (Route.WikiHome { slug = "demo" }))
        , Test.test "/w/elm-tips is WikiHome elm-tips" <|
            \_ ->
                "https://example.com/w/elm-tips"
                    |> Url.fromString
                    |> Maybe.map Route.fromUrl
                    |> Expect.equal (Just (Route.WikiHome { slug = "elm-tips" }))
        , Test.test "/w/demo/articles is WikiArticles demo" <|
            \_ ->
                "https://example.com/w/demo/articles"
                    |> Url.fromString
                    |> Maybe.map Route.fromUrl
                    |> Expect.equal (Just (Route.WikiArticles { slug = "demo" }))
        , Test.test "wiki articles path is not wiki list" <|
            \_ ->
                "https://example.com/w/demo/articles"
                    |> Url.fromString
                    |> Maybe.map (Route.fromUrl >> Route.isWikiList)
                    |> Expect.equal (Just False)
        , Test.test "/w is NotFound" <|
            \_ ->
                "https://example.com/w"
                    |> Url.fromString
                    |> Maybe.map Route.fromUrl
                    |> Maybe.andThen Route.notFoundPath
                    |> Expect.equal (Just "/w")
        , Test.test "/w/ is NotFound" <|
            \_ ->
                "https://example.com/w/"
                    |> Url.fromString
                    |> Maybe.map Route.fromUrl
                    |> Maybe.andThen Route.notFoundPath
                    |> Expect.equal (Just "/w/")
        , Test.test "/w/demo/extra is NotFound" <|
            \_ ->
                "https://example.com/w/demo/extra"
                    |> Url.fromString
                    |> Maybe.map Route.fromUrl
                    |> Maybe.andThen Route.notFoundPath
                    |> Expect.equal (Just "/w/demo/extra")
        , Test.test "storeActions WikiList asks for catalog" <|
            \_ ->
                Route.storeActions Route.WikiList
                    |> Expect.equal [ Store.AskForWikiCatalog ]
        , Test.fuzz Fuzzers.wikiSlug "storeActions WikiHome asks catalog and details" <|
            \slug ->
                Route.storeActions (Route.WikiHome { slug = slug })
                    |> Expect.equal
                        [ Store.AskForWikiCatalog
                        , Store.AskForWikiFrontendDetails slug
                        ]
        , Test.fuzz Fuzzers.wikiSlug "storeActions WikiArticles asks catalog and details" <|
            \slug ->
                Route.storeActions (Route.WikiArticles { slug = slug })
                    |> Expect.equal
                        [ Store.AskForWikiCatalog
                        , Store.AskForWikiFrontendDetails slug
                        ]
        , Test.test "storeActions NotFound asks nothing" <|
            \_ ->
                Url.fromString "https://example.com/nope"
                    |> Maybe.map (Route.fromUrl >> Route.storeActions)
                    |> Expect.equal (Just [])
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

                                Route.WikiHome _ ->
                                    False

                                Route.WikiArticles _ ->
                                    False
                        )
                    |> Expect.equal (Just True)
        ]
