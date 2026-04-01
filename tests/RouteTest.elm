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
    let
        testCases : List ( String, Route.Route )
        testCases =
            [ ( "https://example.com/w/demo", Route.WikiHome "demo" )
            , ( "https://example.com/w/elm-tips", Route.WikiHome "elm-tips" )
            , ( "https://example.com/w/demo/pages", Route.WikiPages "demo" )
            , ( "https://example.com/w/demo/p/guides", Route.WikiPage "demo" "guides" )
            , ( "https://example.com/w/demo/pages/", Route.WikiPages "demo" )
            ]

        toTest : ( String, Route.Route ) -> Test
        toTest ( urlString, expectedRoute ) =
            Test.test urlString <|
                \_ ->
                    urlString
                        |> Url.fromString
                        |> Maybe.map Route.fromUrl
                        |> Expect.equal (Just expectedRoute)
    in
    Test.describe "Route"
        ( testCases
            |> List.map toTest
            |> (++)
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
               , Test.test "/w/demo/guides without /p/ is NotFound" <|
                    \_ ->
                        "https://example.com/w/demo/guides"
                            |> Url.fromString
                            |> Maybe.map Route.fromUrl
                            |> Maybe.andThen Route.notFoundPath
                            |> Expect.equal (Just "/w/demo/guides")
               , Test.test "wiki pages path is not wiki list" <|
                    \_ ->
                        "https://example.com/w/demo/pages"
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
                        Route.storeActions (Route.WikiHome slug)
                            |> Expect.equal
                                [ Store.AskForWikiCatalog
                                , Store.AskForWikiFrontendDetails slug
                                ]
               , Test.fuzz Fuzzers.wikiSlug "storeActions WikiPages asks catalog and details" <|
                    \slug ->
                        Route.storeActions (Route.WikiPages slug)
                            |> Expect.equal
                                [ Store.AskForWikiCatalog
                                , Store.AskForWikiFrontendDetails slug
                                ]
               , Test.fuzz (Fuzz.map2 Tuple.pair Fuzzers.wikiSlug Fuzzers.pageSlug) "storeActions WikiPage asks catalog, details, and published page" <|
                    \( wikiSlug, pageSlug ) ->
                        Route.storeActions (Route.WikiPage wikiSlug pageSlug)
                            |> Expect.equal
                                [ Store.AskForWikiCatalog
                                , Store.AskForWikiFrontendDetails wikiSlug
                                , Store.AskForPageFrontendDetails wikiSlug pageSlug
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

                                        Route.WikiPages _ ->
                                            False

                                        Route.WikiPage _ _ ->
                                            False
                                )
                            |> Expect.equal (Just True)
               ]
        )
