module PageMarkdown exposing (view)

import Html exposing (Html)
import Html.Attributes as Attr
import Markdown.Parser as MarkdownParser
import TW
import Markdown.Renderer as MarkdownRenderer
import Page


{-| Render markdown source as HTML using [dillonkearns/elm-markdown](https://package.elm-lang.org/packages/dillonkearns/elm-markdown/latest/).
-}
view : Page.FrontendDetails -> Html msg
view pageDetails =
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
                |> Result.andThen (MarkdownRenderer.render MarkdownRenderer.defaultHtmlRenderer)
         of
            Ok elements ->
                elements

            Err _ ->
                [ Html.p [] [ Html.text "Could not render this page as Markdown." ] ]
        )
