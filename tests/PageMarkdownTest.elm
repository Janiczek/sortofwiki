module PageMarkdownTest exposing (suite)

import Fuzz
import Html
import Html.Attributes
import Page
import PageMarkdown
import ProgramTest.Query
import Test exposing (Test)
import Test.Html.Query
import Test.Html.Selector
import Url exposing (Url)


wiki : String
wiki =
    "Demo"


pageMarkdownTestOrigin : Url
pageMarkdownTestOrigin =
    Url.fromString "http://localhost:8000/w/Demo/p/Home"
        |> Maybe.withDefault
            { protocol = Url.Http
            , host = "localhost"
            , port_ = Just 8000
            , path = "/w/Demo/p/Home"
            , query = Nothing
            , fragment = Nothing
            }


allPagesExist : Page.Slug -> Bool
allPagesExist _ =
    True


suite : Test
suite =
    Test.describe "PageMarkdown"
        [ Test.describe "view"
            [ Test.test "renders heading from markdown" <|
                \() ->
                    Page.frontendDetails (Just "## Hello\n") [] [] []
                        |> PageMarkdown.view wiki pageMarkdownTestOrigin allPagesExist
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "h2" ]
                        |> Test.Html.Query.has [ Test.Html.Selector.text "Hello" ]
            , Test.test "adds GitHub-style id on headings for TOC anchors" <|
                \() ->
                    Page.frontendDetails (Just "## Hello\n") [] [] []
                        |> PageMarkdown.view wiki pageMarkdownTestOrigin allPagesExist
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "h2" ]
                        |> Test.Html.Query.has [ Test.Html.Selector.attribute (Html.Attributes.id "hello") ]
            , Test.test "renders strong emphasis" <|
                \() ->
                    Page.frontendDetails (Just "**bold**") [] [] []
                        |> PageMarkdown.view wiki pageMarkdownTestOrigin allPagesExist
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "strong" ]
                        |> Test.Html.Query.has [ Test.Html.Selector.text "bold" ]
            , Test.test "renders [[page]] as same-wiki published page link" <|
                \() ->
                    Page.frontendDetails (Just "Go to [[guides]].") [] [] []
                        |> PageMarkdown.view wiki pageMarkdownTestOrigin (\s -> String.toLower s == "guides")
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "a" ]
                        |> Test.Html.Query.has
                            [ Test.Html.Selector.text "guides"
                            , Test.Html.Selector.attribute (Html.Attributes.href "/w/Demo/p/guides")
                            ]
            , Test.test "renders [[slug|label]] with custom link text" <|
                \() ->
                    Page.frontendDetails (Just "[[home|Start here]]") [] [] []
                        |> PageMarkdown.view wiki pageMarkdownTestOrigin (\s -> String.toLower s == "home")
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "a" ]
                        |> Test.Html.Query.has
                            [ Test.Html.Selector.text "Start here"
                            , Test.Html.Selector.attribute (Html.Attributes.href "/w/Demo/p/home")
                            ]
            , Test.test "does not expand wiki link inside inline code" <|
                \() ->
                    Page.frontendDetails (Just "Use `[[home]]` syntax.") [] [] []
                        |> PageMarkdown.view wiki pageMarkdownTestOrigin allPagesExist
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "code" ]
                        |> Test.Html.Query.has [ Test.Html.Selector.text "[[home]]" ]
            , Test.test "renders TODO marker as styled inline text" <|
                \() ->
                    Page.frontendDetails (Just "Ship {TODO: write docs} soon.") [] [] []
                        |> PageMarkdown.view wiki pageMarkdownTestOrigin allPagesExist
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find
                            [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-todo-text" "write docs") ]
                        |> Test.Html.Query.has
                            [ Test.Html.Selector.text "TODO: write docs"
                            , Test.Html.Selector.class "italic"
                            ]
            , Test.test "does not expand TODO marker inside inline code" <|
                \() ->
                    Page.frontendDetails (Just "Use `{TODO: write docs}` syntax.") [] [] []
                        |> PageMarkdown.view wiki pageMarkdownTestOrigin allPagesExist
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "code" ]
                        |> Test.Html.Query.has [ Test.Html.Selector.text "{TODO: write docs}" ]
            , Test.test "inline link URL may contain balanced parentheses (Wikipedia-style path)" <|
                \() ->
                    Page.frontendDetails
                        (Just "[On Wikipedia](https://cs.wikipedia.org/wiki/Hani%C4%8Dka_(d%C4%9Blost%C5%99eleck%C3%A1_tvrz)).\n")
                        []
                        []
                        []
                        |> PageMarkdown.view wiki pageMarkdownTestOrigin allPagesExist
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "a" ]
                        |> Test.Html.Query.has
                            [ Test.Html.Selector.text "On Wikipedia"
                            , Test.Html.Selector.attribute
                                (Html.Attributes.href
                                    "https://cs.wikipedia.org/wiki/Hani%C4%8Dka_%28d%C4%9Blost%C5%99eleck%C3%A1_tvrz%29"
                                )
                            , Test.Html.Selector.attribute (Html.Attributes.target "_blank")
                            , Test.Html.Selector.attribute (Html.Attributes.rel "noopener noreferrer")
                            ]
            , Test.test "same-origin absolute http link does not open in new tab" <|
                \() ->
                    Page.frontendDetails (Just "[stay](http://localhost:8000/w/Demo/p/Other)") [] [] []
                        |> PageMarkdown.view wiki pageMarkdownTestOrigin allPagesExist
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "a" ]
                        |> Test.Html.Query.hasNot [ Test.Html.Selector.attribute (Html.Attributes.target "_blank") ]
            , Test.test "renders $$...$$ as inline-equation custom element" <|
                \() ->
                    Page.frontendDetails (Just "Inline $$x^2 + y^2$$ math.") [] [] []
                        |> PageMarkdown.view wiki pageMarkdownTestOrigin allPagesExist
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find
                            [ Test.Html.Selector.tag "inline-equation"
                            , Test.Html.Selector.attribute (Html.Attributes.attribute "data-equation" "x^2 + y^2")
                            ]
                        |> Test.Html.Query.has []
            , Test.test "renders $$$...$$$ as block-equation custom element" <|
                \() ->
                    Page.frontendDetails (Just "Before\n\n$$$x^2 + y^2$$$\n\nAfter") [] [] []
                        |> PageMarkdown.view wiki pageMarkdownTestOrigin allPagesExist
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find
                            [ Test.Html.Selector.tag "block-equation"
                            , Test.Html.Selector.attribute (Html.Attributes.attribute "data-equation" "x^2 + y^2")
                            ]
                        |> Test.Html.Query.has []
            , Test.fuzz (Fuzz.map String.fromInt (Fuzz.intRange 0 999999)) "heading line with numeric title renders as h2 text" <|
                \title ->
                    Page.frontendDetails (Just ("## " ++ title ++ "\n")) [] [] []
                        |> PageMarkdown.view wiki pageMarkdownTestOrigin allPagesExist
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "h2" ]
                        |> Test.Html.Query.has [ Test.Html.Selector.text title ]
            , Test.fuzz (Fuzz.intRange 0 99999) "[[slug]] link href uses wiki path segment" <|
                \n ->
                    let
                        slug : String
                        slug =
                            "pg" ++ String.fromInt n
                    in
                    Page.frontendDetails (Just ("[[" ++ slug ++ "]]")) [] [] []
                        |> PageMarkdown.view wiki pageMarkdownTestOrigin allPagesExist
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "a" ]
                        |> Test.Html.Query.has
                            [ Test.Html.Selector.attribute (Html.Attributes.href ("/w/Demo/p/" ++ slug))
                            ]
            , Test.test "[[missing]] uses missing-wiki-link styling when slug not published" <|
                \() ->
                    Page.frontendDetails (Just "See [[ghost]].") [] [] []
                        |> PageMarkdown.view wiki pageMarkdownTestOrigin (\_ -> False)
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "a" ]
                        |> Test.Html.Query.has
                            [ Test.Html.Selector.text "ghost"
                            , Test.Html.Selector.attribute (Html.Attributes.href "/w/Demo/p/ghost")
                            , Test.Html.Selector.class "!text-red-700"
                            ]
            , Test.test "renders [[slug|label]] inside markdown table cell" <|
                \() ->
                    Page.frontendDetails
                        (Just """| Supporting skill | Receiving skill |
| - | - |
| [[AlgorithmsSkill|Algorithms]] | [[CombatSkill|Combat]] |
""")
                        []
                        []
                        []
                        |> PageMarkdown.view wiki pageMarkdownTestOrigin (\slug -> List.member slug [ "AlgorithmsSkill", "CombatSkill" ])
                        |> Test.Html.Query.fromHtml
                        |> ProgramTest.Query.withinTag "table"
                            (ProgramTest.Query.expectAll
                                [ ProgramTest.Query.expectLink
                                    { href = "/w/Demo/p/AlgorithmsSkill"
                                    , label = "Algorithms"
                                    }
                                , ProgramTest.Query.expectLink
                                    { href = "/w/Demo/p/CombatSkill"
                                    , label = "Combat"
                                    }
                                ]
                            )
            ]
        , Test.describe "viewPreview"
            [ Test.test "uses given container id" <|
                \() ->
                    Html.div []
                        [ PageMarkdown.viewPreview "custom-md-preview" wiki pageMarkdownTestOrigin allPagesExist "# Hi\n" ]
                        |> Test.Html.Query.fromHtml
                        |> Test.Html.Query.find [ Test.Html.Selector.id "custom-md-preview" ]
                        |> Test.Html.Query.find [ Test.Html.Selector.tag "h1" ]
                        |> Test.Html.Query.has [ Test.Html.Selector.text "Hi" ]
            ]
        ]
