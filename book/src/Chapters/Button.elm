module Chapters.Button exposing (chapter_)

import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Html
import UI.Button


chapter_ : Chapter x
chapter_ =
    chapter "UI.Button"
        |> renderComponentList
            [ ( "UI.Button.button"
              , UI.Button.button [] [ Html.text "Primary" ]
              )
            , ( "UI.Button.dangerButton"
              , UI.Button.dangerButton [] [ Html.text "Delete" ]
              )
            ]
