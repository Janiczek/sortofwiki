module Chapters.FocusVisible exposing (chapter_)

import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Html
import Html.Attributes as Attr
import TW
import UI.FocusVisible


chapter_ : Chapter x
chapter_ =
    chapter "UI.FocusVisible"
        |> renderComponentList
            [ ( "UI.FocusVisible.on (on fake link)"
              , Html.a
                    (UI.FocusVisible.on
                        [ Attr.href "#"
                        , TW.cls "text-[var(--link)] underline"
                        ]
                    )
                    [ Html.text "focus-visible ring" ]
              )
            ]
