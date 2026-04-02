module PageTocTest exposing (suite)

import Expect
import Html.Attributes
import Markdown.Block as Block
import Page
import PageToc
import Test exposing (Test)
import Test.Html.Query
import Test.Html.Selector


wiki : String
wiki =
    "demo"


suite : Test
suite =
    Test.describe "PageToc"
        [ Test.describe "entries"
            [ Test.test "collects heading labels and slugs" <|
                \() ->
                    Page.frontendDetails "## First\n\n### Second one\n" []
                        |> PageToc.entries wiki
                        |> Expect.equal
                            [ { level = Block.H2, label = "First", slug = "first" }
                            , { level = Block.H3, label = "Second one", slug = "second-one" }
                            ]
            , Test.test "empty for plain paragraph markdown" <|
                \() ->
                    Page.frontendDetails "Just text." []
                        |> PageToc.entries wiki
                        |> Expect.equal []
            ]
        , Test.describe "view"
            [ Test.test "empty list renders no nodes" <|
                \() ->
                    PageToc.view []
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.hasNot [ Test.Html.Selector.tag "nav" ]
            , Test.test "non-empty renders nav with fragment link" <|
                \() ->
                    [ { level = Block.H2, label = "Intro", slug = "intro" } ]
                        |> PageToc.view
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find
                            [ Test.Html.Selector.tag "a"
                            , Test.Html.Selector.attribute (Html.Attributes.href "#intro")
                            ]
                        |> Test.Html.Query.has [ Test.Html.Selector.text "Intro" ]
            ]
        ]

