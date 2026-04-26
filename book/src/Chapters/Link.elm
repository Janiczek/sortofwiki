module Chapters.Link exposing (chapter_)

import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Html
import Html.Attributes as Attr
import UI.Link


chapter_ : Chapter x
chapter_ =
    chapter "UI.Link"
        |> renderComponentList
            [ ( "UI.Link.contentLink"
              , UI.Link.contentLink [ Attr.href "#" ] [ Html.text "Link module" ]
              )
            ]
