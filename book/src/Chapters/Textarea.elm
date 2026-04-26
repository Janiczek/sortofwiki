module Chapters.Textarea exposing (chapter_)

import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Html
import Html.Attributes as Attr
import UI.Textarea


chapter_ : Chapter x
chapter_ =
    chapter "UI.Textarea"
        |> renderComponentList
            [ ( "formAttr (default tall)"
              , Html.textarea
                    (UI.Textarea.form [ Attr.placeholder "Tall textarea..." ])
                    []
              )
            , ( "formCompactAttr"
              , Html.textarea
                    (UI.Textarea.formCompact [ Attr.placeholder "Compact textarea..." ])
                    []
              )
            , ( "formAttr with extra attrs"
              , Html.textarea
                    (UI.Textarea.form
                        [ Attr.placeholder "Configurable via attrs"
                        , Attr.rows 10
                        ]
                    )
                    []
              )
            , ( "formCompactAttr disabled"
              , Html.textarea
                    (UI.Textarea.formCompact
                        [ Attr.placeholder "Disabled compact textarea"
                        , Attr.disabled True
                        ]
                    )
                    []
              )
            , ( "readonly markdown diff cell"
              , Html.textarea
                    (UI.Textarea.markdownReadonlyCol1Row2 [ Attr.readonly True ])
                    [ Html.text "Readonly markdown style used in review flow." ]
              )
            ]
