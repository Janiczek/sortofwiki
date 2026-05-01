module Chapters.FormActionFooter exposing (chapter_)

import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Html
import TW
import UI.Button
import UI.FormActionFooter
import UI.SubmissionActions


chapter_ : Chapter x
chapter_ =
    chapter "UI.FormActionFooter"
        |> renderComponentList
            [ ( "FormActionFooter.sticky - AlignEnd"
              , Html.div
                    [ TW.cls "relative flex h-36 flex-col overflow-hidden rounded-lg border border-dashed border-[var(--border-subtle)]" ]
                    [ Html.div [ TW.cls "min-h-0 flex-1 p-2 text-[0.8125rem] text-[var(--fg-muted)]" ]
                        [ Html.text "Form body; footer sticks to bottom of this box." ]
                    , UI.FormActionFooter.sticky
                        { align = UI.FormActionFooter.AlignEnd
                        , left = []
                        , right =
                            [ UI.Button.button [] [ Html.text "Save draft" ]
                            , UI.Button.button [] [ Html.text "Submit" ]
                            ]
                        }
                    ]
              )
            , ( "FormActionFooter.sticky - AlignBetween"
              , Html.div
                    [ TW.cls "relative flex h-36 flex-col overflow-hidden rounded-lg border border-dashed border-[var(--border-subtle)]" ]
                    [ Html.div [ TW.cls "min-h-0 flex-1 p-2 text-[0.8125rem] text-[var(--fg-muted)]" ]
                        [ Html.text "Disclaimer + actions (submit-edit pattern)." ]
                    , UI.FormActionFooter.sticky
                        { align = UI.FormActionFooter.AlignBetween
                        , left =
                            [ Html.p [ TW.cls "m-0 max-w-[14rem] text-[0.8125rem] text-[var(--fg-muted)]" ]
                                [ Html.text "Reviewer must approve before changes go live." ]
                            ]
                        , right =
                            [ UI.SubmissionActions.primaryPairRow
                                { saveDraftAttrs = []
                                , submitAttrs = []
                                , submitLabel = "Submit for review"
                                }
                            ]
                        }
                    ]
              )
            ]
