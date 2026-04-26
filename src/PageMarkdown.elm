module PageMarkdown exposing (view, viewPreview)

import Html exposing (Html)
import Html.Attributes as Attr
import Markdown.Block as Block
import Markdown.Html
import Markdown.Renderer as MarkdownRenderer
import Page
import UI
import UI.FocusVisible
import Wiki
import WikiPageMarkdownParse
import UI.Link
import UI.Heading


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
                    [ UI.contentParagraph [] [ Html.text "Could not render this page as Markdown." ] ]
    in
    Html.div
        [ Attr.id containerId
        , UI.markdownContainerAttr
        ]
        [ Html.div
            [ UI.minW0Attr ]
            body
        ]


{-| Same as `viewPreview` with id `page-markdown` (published page body).
-}
view : Wiki.Slug -> (Page.Slug -> Bool) -> Page.FrontendDetails -> Html msg
view wikiSlug publishedSlugExists pageDetails =
    case pageDetails.maybeMarkdownSource of
        Just markdownSource ->
            viewPreview "page-markdown" wikiSlug publishedSlugExists markdownSource

        Nothing ->
            Html.text ""


htmlRendererWithHeadingIds : Maybe String -> MarkdownRenderer.Renderer (Html msg)
htmlRendererWithHeadingIds maybeSlug =
    let
        base : MarkdownRenderer.Renderer (Html msg)
        base =
            MarkdownRenderer.defaultHtmlRenderer

        headingAttrs : List (Html.Attribute msg)
        headingAttrs =
            maybeSlug
                |> Maybe.map Attr.id
                |> Maybe.map List.singleton
                |> Maybe.withDefault []
    in
    { base
        | heading =
            \{ level, children } ->
                case level of
                    Block.H1 ->
                        UI.Heading.markdownHeading1 headingAttrs children

                    Block.H2 ->
                        UI.Heading.markdownHeading2 headingAttrs children

                    Block.H3 ->
                        UI.Heading.markdownHeading3 headingAttrs children

                    Block.H4 ->
                        UI.Heading.markdownHeading4 headingAttrs children

                    Block.H5 ->
                        UI.Heading.markdownHeading5 headingAttrs children

                    Block.H6 ->
                        UI.Heading.markdownHeading6 headingAttrs children
        , paragraph =
            \children ->
                Html.p [ UI.markdownParagraphAttr ] children
        , blockQuote =
            \children ->
                Html.blockquote [ UI.markdownBlockQuoteAttr ] children
        , codeSpan =
            \code ->
                Html.code [ UI.markdownCodeSpanAttr ] [ Html.text code ]
        , link =
            \{ title, destination } children ->
                case title of
                    Just "sortofwiki:missing" ->
                        UI.Link.missingLink [ Attr.href destination ] children

                    _ ->
                        UI.Link.contentLink
                            ([ Attr.href destination ]
                                ++ (title
                                        |> Maybe.map Attr.title
                                        |> Maybe.map List.singleton
                                        |> Maybe.withDefault []
                                   )
                            )
                            children
        , unorderedList =
            \items ->
                Html.ul [ UI.markdownUnorderedListAttr ]
                    (List.map markdownListItemHtml items)
        , orderedList =
            \startIndex items ->
                Html.ol
                    [ UI.markdownOrderedListAttr
                    , Attr.start startIndex
                    ]
                    (items
                        |> List.map (\children -> Html.li [ UI.markdownListItemAttr ] children)
                    )
        , table =
            \children ->
                Html.table [ UI.markdownTableAttr ] children
        , tableHeader =
            \children ->
                Html.thead [] children
        , tableBody =
            \children ->
                Html.tbody [] children
        , tableRow =
            \children ->
                Html.tr [ UI.markdownTableRowAttr ] children
        , tableHeaderCell =
            \alignment children ->
                Html.th
                    (UI.markdownTableHeaderCellAttr :: tableAlignmentAttrs alignment)
                    children
        , tableCell =
            \alignment children ->
                Html.td
                    (UI.markdownTableCellAttr :: tableAlignmentAttrs alignment)
                    children
        , codeBlock =
            \{ body } ->
                Html.pre [ UI.markdownCodeBlockPreAttr ]
                    [ Html.code [ UI.markdownCodeBlockCodeAttr ] [ Html.text body ] ]
        , html =
            Markdown.Html.oneOf
                [ Markdown.Html.tag "inline-equation" inlineEquationHtml
                    |> Markdown.Html.withAttribute "data-equation"
                , Markdown.Html.tag "block-equation" blockEquationHtml
                    |> Markdown.Html.withAttribute "data-equation"
                , Markdown.Html.tag "sortofwiki-todo" todoHtml
                    |> Markdown.Html.withAttribute "data-todo"
                ]
        , thematicBreak =
            Html.hr [ UI.markdownThematicBreakAttr ] []
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


tableAlignmentAttrs : Maybe Block.Alignment -> List (Html.Attribute msg)
tableAlignmentAttrs maybeAlignment =
    case maybeAlignment of
        Just Block.AlignLeft ->
            [ Attr.style "text-align" "left" ]

        Just Block.AlignCenter ->
            [ Attr.style "text-align" "center" ]

        Just Block.AlignRight ->
            [ Attr.style "text-align" "right" ]

        Nothing ->
            []


markdownListItemHtml : Block.ListItem (Html msg) -> Html msg
markdownListItemHtml listItem =
    case listItem of
        Block.ListItem task children ->
            case task of
                Block.NoTask ->
                    Html.li [ UI.markdownListItemAttr ] children

                Block.IncompleteTask ->
                    Html.li [ UI.markdownListItemAttr ]
                        [ Html.input
                            ([ Attr.type_ "checkbox"
                             , Attr.checked False
                             , Attr.disabled True
                             ]
                                |> UI.FocusVisible.on
                            )
                            []
                        , Html.text " "
                        , Html.span [] children
                        ]

                Block.CompletedTask ->
                    Html.li [ UI.markdownListItemAttr ]
                        [ Html.input
                            ([ Attr.type_ "checkbox"
                             , Attr.checked True
                             , Attr.disabled True
                             ]
                                |> UI.FocusVisible.on
                            )
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


todoHtml : String -> List (Html msg) -> Html msg
todoHtml todoText _ =
    Html.em
        [ UI.markdownTodoAttr
        , Attr.attribute "data-todo-text" todoText
        ]
        [ Html.text ("TODO: " ++ todoText) ]
