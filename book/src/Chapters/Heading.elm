module Chapters.Heading exposing (chapter_)

import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Html
import UI.Heading


chapter_ : Chapter x
chapter_ =
    chapter "UI.Heading"
        |> renderComponentList
            [ ( "UI.Heading.contentHeading2"
              , UI.Heading.contentHeading2 [] [ Html.text "Heading module" ]
              )
            , ( "UI.Heading.markdownHeading2"
              , UI.Heading.markdownHeading2 [] [ Html.text "Markdown-sized heading" ]
              )
            ]
