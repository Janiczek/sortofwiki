module PageMarkdown exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr
import Markdown.Block as Block
import Markdown.Renderer as MarkdownRenderer
import Page
import TW
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
        , TW.cls "max-w-[52rem] text-[0.95rem] font-serif"
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
    in
    { base
        | heading =
            \{ level, children } ->
                headingHtml maybeSlug level children
    }


headingHtml : Maybe String -> Block.HeadingLevel -> List (Html msg) -> Html msg
headingHtml maybeSlug level children =
    let
        attrs : List (Html.Attribute msg)
        attrs =
            maybeSlug
                |> Maybe.map Attr.id
                |> Maybe.map List.singleton
                |> Maybe.withDefault []
    in
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
