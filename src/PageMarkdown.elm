module PageMarkdown exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr
import Markdown.Parser as MarkdownParser
import Markdown.Renderer as MarkdownRenderer
import Page
import TW
import Wiki
import WikiMarkdown


{-| Render markdown source as HTML using [dillonkearns/elm-markdown](https://package.elm-lang.org/packages/dillonkearns/elm-markdown/latest/).
Wiki links `[[page-slug]]` and `[[page-slug|label]]` in text become in-wiki links before HTML rendering.
-}
view : Wiki.Slug -> Page.FrontendDetails -> Html msg
view wikiSlug pageDetails =
    Html.div
        [ Attr.id "page-markdown"
        , TW.cls "page-markdown-inner"
        ]
        (case
            pageDetails.markdownSource
                |> MarkdownParser.parse
                |> Result.mapError
                    (\deadEnds ->
                        deadEnds
                            |> List.map MarkdownParser.deadEndToString
                            |> String.join "\n"
                    )
                |> Result.map (WikiMarkdown.postProcessBlocksWithWikiLinks wikiSlug)
                |> Result.andThen (MarkdownRenderer.render MarkdownRenderer.defaultHtmlRenderer)
         of
            Ok elements ->
                elements

            Err _ ->
                [ Html.p [] [ Html.text "Could not render this page as Markdown." ] ]
        )
