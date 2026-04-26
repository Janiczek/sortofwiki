module Chapters.AsyncState exposing (chapter_)

import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import UI.AsyncState


chapter_ : Chapter x
chapter_ =
    chapter "UI.AsyncState"
        |> renderComponentList
            [ ( "AsyncState.loading"
              , UI.AsyncState.loading "Loading..."
              )
            , ( "AsyncState.empty (= EmptyState.status)"
              , UI.AsyncState.empty { id = "book-async-empty", text = "Nothing here yet." }
              )
            ]
