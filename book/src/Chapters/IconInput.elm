module Chapters.IconInput exposing (chapter_)

import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Html
import Html.Attributes as Attr
import TW
import UI
import UI.IconInput


chapter_ : Chapter x
chapter_ =
    chapter "UI.IconInput"
        |> renderComponentList
            [ ( "IconInput.text (login-style)"
              , Html.div [ TW.cls "max-w-xs space-y-3" ]
                    [ UI.contentLabel [ Attr.for "book-icon-user" ] [ Html.text "Username" ]
                    , UI.IconInput.view
                        { icon = Html.span [] [ Html.text "*" ]
                        , attrs =
                            [ Attr.id "book-icon-user"
                            , Attr.type_ "text"
                            , Attr.value "reader"
                            , Attr.class "opacity-80"
                            , UI.formTextInputAttr
                            ]
                        }
                    , UI.contentLabel [ Attr.for "book-icon-pass" ] [ Html.text "Password" ]
                    , UI.IconInput.view
                        { icon = Html.span [] [ Html.text "*" ]
                        , attrs =
                            [ Attr.id "book-icon-pass"
                            , Attr.type_ "password"
                            , Attr.value ""
                            , UI.formTextInputAttr
                            ]
                        }
                    ]
              )
            ]
