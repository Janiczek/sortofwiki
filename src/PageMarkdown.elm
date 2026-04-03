module PageMarkdown exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr
import Markdown.Block as Block
import Markdown.Renderer as MarkdownRenderer
import Page
import TW
import UI
import Wiki
import WikiPageMarkdownParse


{-| Render markdown source as HTML using [dillonkearns/elm-markdown](https://package.elm-lang.org/packages/dillonkearns/elm-markdown/latest/).
Wiki links `[[page-slug]]` and `[[page-slug|label]]` in text become in-wiki links before HTML rendering.
Headings receive GitHub-style `id` attributes so the table of contents can link to them.
-}
view : Wiki.Slug -> Page.FrontendDetails -> Html msg
view wikiSlug pageDetails =
    Html.div
        [ Attr.id "page-markdown"
        , TW.cls UI.markdownContainerClass
        ]
        (case
            WikiPageMarkdownParse.blocksWithHeadingSlugs wikiSlug pageDetails.markdownSource
                |> Result.andThen (MarkdownRenderer.renderWithMeta htmlRendererWithHeadingIds)
         of
            Ok elements ->
                elements

            Err _ ->
                [ Html.p [] [ Html.text "Could not render this page as Markdown." ] ]
        )


htmlRendererWithHeadingIds : Maybe String -> MarkdownRenderer.Renderer (Html msg)
htmlRendererWithHeadingIds maybeSlug =
    let
        base : MarkdownRenderer.Renderer (Html msg)
        base =
            MarkdownRenderer.defaultHtmlRenderer

        headingAttrs : Block.HeadingLevel -> List (Html.Attribute msg)
        headingAttrs level =
            let
                levelClass : String
                levelClass =
                    case level of
                        Block.H1 ->
                            UI.markdownHeading1Class

                        Block.H2 ->
                            UI.markdownHeading2Class

                        Block.H3 ->
                            UI.markdownHeading3Class

                        Block.H4 ->
                            UI.markdownHeading4Class

                        Block.H5 ->
                            UI.markdownHeading5Class

                        Block.H6 ->
                            UI.markdownHeading6Class
            in
            TW.cls levelClass
                :: (maybeSlug
                        |> Maybe.map Attr.id
                        |> Maybe.map List.singleton
                        |> Maybe.withDefault []
                   )
    in
    { base
        | heading =
            \{ level, children } ->
                headingHtml (headingAttrs level) level children
        , paragraph =
            \children ->
                Html.p [ TW.cls UI.markdownParagraphClass ] children
        , blockQuote =
            \children ->
                Html.blockquote [ TW.cls UI.markdownBlockQuoteClass ] children
        , codeSpan =
            \code ->
                Html.code [ TW.cls UI.markdownCodeSpanClass ] [ Html.text code ]
        , link =
            \{ title, destination } children ->
                Html.a
                    ([ TW.cls UI.markdownLinkClass
                     , Attr.href destination
                     ]
                        ++ (title
                                |> Maybe.map Attr.title
                                |> Maybe.map List.singleton
                                |> Maybe.withDefault []
                           )
                    )
                    children
        , unorderedList =
            \items ->
                Html.ul [ TW.cls UI.markdownUnorderedListClass ]
                    (List.map markdownListItemHtml items)
        , orderedList =
            \startIndex items ->
                Html.ol
                    [ TW.cls UI.markdownOrderedListClass
                    , Attr.start startIndex
                    ]
                    (items
                        |> List.map (\children -> Html.li [ TW.cls UI.markdownListItemClass ] children)
                    )
        , codeBlock =
            \{ body } ->
                Html.pre [ TW.cls UI.markdownCodeBlockPreClass ]
                    [ Html.code [ TW.cls UI.markdownCodeBlockCodeClass ] [ Html.text body ] ]
        , thematicBreak =
            Html.hr [ TW.cls UI.markdownThematicBreakClass ] []
    }


headingHtml : List (Html.Attribute msg) -> Block.HeadingLevel -> List (Html msg) -> Html msg
headingHtml attrs level children =
    case level of
        Block.H1 ->
            Html.h1 attrs children

        Block.H2 ->
            Html.h2 attrs children

        Block.H3 ->
            Html.h3 attrs children

        Block.H4 ->
            Html.h4 attrs children

        Block.H5 ->
            Html.h5 attrs children

        Block.H6 ->
            Html.h6 attrs children


markdownListItemHtml : Block.ListItem (Html msg) -> Html msg
markdownListItemHtml listItem =
    case listItem of
        Block.ListItem task children ->
            case task of
                Block.NoTask ->
                    Html.li [ TW.cls UI.markdownListItemClass ] children

                Block.IncompleteTask ->
                    Html.li [ TW.cls UI.markdownListItemClass ]
                        [ Html.input
                            [ Attr.type_ "checkbox"
                            , Attr.checked False
                            , Attr.disabled True
                            ]
                            []
                        , Html.text " "
                        , Html.span [] children
                        ]

                Block.CompletedTask ->
                    Html.li [ TW.cls UI.markdownListItemClass ]
                        [ Html.input
                            [ Attr.type_ "checkbox"
                            , Attr.checked True
                            , Attr.disabled True
                            ]
                            []
                        , Html.text " "
                        , Html.span [] children
                        ]
