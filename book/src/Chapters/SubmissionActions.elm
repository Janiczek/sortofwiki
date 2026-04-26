module Chapters.SubmissionActions exposing (chapter_)

import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Html
import TW
import UI.SubmissionActions


chapter_ : Chapter x
chapter_ =
    chapter "UI.SubmissionActions"
        |> renderComponentList
            [ ( "SubmissionActions - pair list (AlignEnd footer)"
              , Html.footer [ TW.cls "flex justify-end gap-2 border-t border-[var(--border-subtle)] px-4 py-2 bg-[var(--bg)]" ]
                    (UI.SubmissionActions.primaryPairButtons
                        { saveDraftAttrs = []
                        , submitAttrs = []
                        , submitLabel = "Create"
                        }
                    )
              )
            ]
