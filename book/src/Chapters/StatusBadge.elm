module Chapters.StatusBadge exposing (chapter_)

import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import UI.StatusBadge


chapter_ : Chapter x
chapter_ =
    chapter "UI.StatusBadge"
        |> renderComponentList
            [ ( "UI.StatusBadge.view — active"
              , UI.StatusBadge.view { isActive = True, text = "Active" }
              )
            , ( "UI.StatusBadge.view — inactive"
              , UI.StatusBadge.view { isActive = False, text = "Inactive" }
              )
            ]
