module Chapters.EmptyState exposing (chapter_)

import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import UI.EmptyState


chapter_ : Chapter x
chapter_ =
    chapter "UI.EmptyState"
        |> renderComponentList
            [ ( "EmptyState.paragraph"
              , UI.EmptyState.paragraph { id = "book-empty-paragraph", text = "No rows in this list." }
              )
            ]
