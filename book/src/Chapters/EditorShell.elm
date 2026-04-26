module Chapters.EditorShell exposing (chapter_)

import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Html
import TW
import UI.EditorShell


chapter_ : Chapter x
chapter_ =
    chapter "UI.EditorShell"
        |> renderComponentList
            [ ( "UI.EditorShell.view"
              , Html.div [ TW.cls "max-w-2xl space-y-2" ]
                    [ UI.EditorShell.view
                        { containerAttrs = [ TW.cls "min-h-[8rem]" ]
                        , controlsAttrs = [ TW.cls "p-2 text-[0.8rem]" ]
                        , controlsChildren = [ Html.text "toolbar" ]
                        , contentAttrs = [ TW.cls "min-h-[5rem]" ]
                        , contentChildren =
                            [ Html.div [ TW.cls "p-2 bg-[var(--input-bg)] text-[0.75rem]" ] [ Html.text "col a" ]
                            , Html.div [ TW.cls "p-2 bg-[var(--bg)] text-[0.75rem]" ] [ Html.text "col b" ]
                            ]
                        }
                    ]
              )
            ]
