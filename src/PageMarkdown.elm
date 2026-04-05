module PageMarkdown exposing (view, viewPreview)

import Html exposing (Html)
import Html.Attributes as Attr
import Markdown.Block as Block
import Markdown.Html
import Markdown.Renderer as MarkdownRenderer
import Page
import TW
import UI
import Wiki
import WikiPageMarkdownParse


{-| Render markdown source as HTML using [dillonkearns/elm-markdown](https://package.elm-lang.org/packages/dillonkearns/elm-markdown/latest/).
Wiki links `[[page-slug]]` and `[[page-slug|label]]` in text become in-wiki links before HTML rendering.
Headings receive GitHub-style `id` attributes so the table of contents can link to them.
Use a distinct `containerId` when several previews appear on one page.
-}
viewPreview : String -> Wiki.Slug -> (Page.Slug -> Bool) -> String -> Html msg
viewPreview containerId wikiSlug publishedSlugExists markdownSource =
    let
        body : List (Html msg)
        body =
            case
                WikiPageMarkdownParse.blocksWithHeadingSlugs wikiSlug publishedSlugExists markdownSource
                    |> Result.andThen (MarkdownRenderer.renderWithMeta htmlRendererWithHeadingIds)
            of
                Ok elements ->
                    elements

                Err _ ->
                    [ Html.p [] [ Html.text "Could not render this page as Markdown." ] ]
    in
    Html.div
        [ Attr.id containerId
        , TW.cls UI.markdownContainerClass
        ]
        [ Html.div
            [ TW.cls "min-w-0" ]
            body
        ]


{-| Same as `viewPreview` with id `page-markdown` (published page body).
-}
view : Wiki.Slug -> (Page.Slug -> Bool) -> Page.FrontendDetails -> Html msg
view wikiSlug publishedSlugExists pageDetails =
    viewPreview "page-markdown" wikiSlug publishedSlugExists pageDetails.markdownSource


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
                let
                    ( linkClass, titleAttr ) =
                        case title of
                            Just "sortofwiki:missing" ->
                                ( UI.markdownWikiLinkMissingClass, Nothing )

                            _ ->
                                ( UI.markdownLinkClass, title )
                in
                Html.a
                    ([ TW.cls linkClass
                     , Attr.href destination
                     ]
                        ++ (titleAttr
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
        , html =
            Markdown.Html.oneOf
                [ Markdown.Html.tag "inline-equation" inlineEquationHtml
                    |> Markdown.Html.withAttribute "data-equation"
                , Markdown.Html.tag "block-equation" blockEquationHtml
                    |> Markdown.Html.withAttribute "data-equation"
                ]
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


inlineEquationHtml : String -> List (Html msg) -> Html msg
inlineEquationHtml equation _ =
    Html.node "inline-equation"
        [ Attr.attribute "data-equation" equation ]
        []


blockEquationHtml : String -> List (Html msg) -> Html msg
blockEquationHtml equation _ =
    Html.node "block-equation"
        [ Attr.attribute "data-equation" equation ]
        []
