module PageTest exposing (suite)

import Expect
import Fuzz
import Page
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Page"
        [ Test.describe "frontendDetails"
            [ Test.test "maps markdown argument to markdownSource" <|
                \() ->
                    Page.frontendDetails "## Hi\n" []
                        |> Expect.equal { markdownSource = "## Hi\n", backlinks = [] }
            , Test.fuzz Fuzz.string "markdownSource equals first argument" <|
                \markdownSource ->
                    let
                        fd : Page.FrontendDetails
                        fd =
                            Page.frontendDetails markdownSource []
                    in
                    fd.markdownSource
                        |> Expect.equal markdownSource
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
        , Test.describe "titleHintFromMarkdown"
            [ Test.test "reads first ATX H1" <|
                \() ->
                    Page.titleHintFromMarkdown "# Guides\n\nBody"
                        |> Expect.equal (Just "Guides")
            , Test.test "strips optional closing hashes" <|
                \() ->
                    Page.titleHintFromMarkdown "# Guides #\n"
                        |> Expect.equal (Just "Guides")
            , Test.test "Nothing when no leading H1" <|
                \() ->
                    Page.titleHintFromMarkdown "Intro\n\n# Later"
                        |> Expect.equal Nothing
            , Test.test "Nothing for empty H1" <|
                \() ->
                    Page.titleHintFromMarkdown "# \n"
                        |> Expect.equal Nothing
            ]
        , Test.describe "publishedPageTitle"
            [ Test.test "uses H1 over slug" <|
                \() ->
                    Page.publishedPageTitle "guides" (Page.frontendDetails "# How to\n" [])
                        |> Expect.equal "How to"
            , Test.test "falls back to slug" <|
                \() ->
                    Page.publishedPageTitle "guides" (Page.frontendDetails "No heading\n" [])
                        |> Expect.equal "guides"
            ]
        ]
