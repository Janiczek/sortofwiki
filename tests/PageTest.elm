module PageTest exposing (suite)

import Expect
import Fuzz
import Page
import Test exposing (Test)


suite : Test
suite =
    Test.describe "Page"
        [ Test.describe "frontendDetails"
            [ Test.test "maps stored content to markdownSource" <|
                \() ->
                    Page.frontendDetails { slug = "home", content = "## Hi\n" }
                        |> Expect.equal { markdownSource = "## Hi\n" }
            , Test.fuzz Fuzz.string "markdownSource equals page content" <|
                \content ->
                    let
                        fd : Page.FrontendDetails
                        fd =
                            Page.frontendDetails { slug = "p", content = content }
                    in
                    fd.markdownSource
                        |> Expect.equal content
            ]
        ]
