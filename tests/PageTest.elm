module PageTest exposing (suite)

import Expect
import Fuzz
import Page
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Page"
        [ Test.describe "frontendDetails"
            [ Test.test "maps markdown argument to maybeMarkdownSource" <|
                \() ->
                    Page.frontendDetails (Just "## Hi\n") [] [] []
                        |> Expect.equal
                            { maybeMarkdownSource = Just "## Hi\n"
                            , backlinks = []
                            , tags = []
                            , taggedPageSlugs = []
                            }
            , Test.fuzz Fuzz.string "maybeMarkdownSource equals first argument" <|
                \markdownSource ->
                    let
                        fd : Page.FrontendDetails
                        fd =
                            Page.frontendDetails (Just markdownSource) [] [] []
                    in
                    fd.maybeMarkdownSource
                        |> Expect.equal (Just markdownSource)
            ]
        , Test.describe "hasPublished"
            [ Test.test "False for pending-only" <|
                \() ->
                    Page.pendingOnly "x" "draft"
                        |> Page.hasPublished
                        |> Expect.equal False
            , Test.test "True when published present" <|
                \() ->
                    Page.withPublished "x" "hi"
                        |> Page.hasPublished
                        |> Expect.equal True
            , Test.fuzz Fuzz.string "withPublished always hasPublished" <|
                \s ->
                    Page.withPublished "slug" s
                        |> Page.hasPublished
                        |> Expect.equal True
            ]
        , Test.describe "publishedMarkdownForLinks"
            [ Test.test "empty when not published" <|
                \() ->
                    Page.pendingOnly "a" "[[b]]"
                        |> Page.publishedMarkdownForLinks
                        |> Expect.equal ""
            , Test.test "uses published, ignores pending link targets" <|
                \() ->
                    Page.withPublishedAndPending "a" "no link here" "[[secret]]"
                        |> Page.publishedMarkdownForLinks
                        |> Expect.equal "no link here"
            , Test.fuzz Fuzz.string "withPublished body equals publishedMarkdownForLinks" <|
                \s ->
                    Page.withPublished "slug" s
                        |> Page.publishedMarkdownForLinks
                        |> Expect.equal s
            ]
        ]
