module Chapters.FormControls exposing (chapterChips, chapter_)

import ElmBook.Actions
import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList, renderStatefulComponentList)
import Html
import Html.Attributes as Attr
import SharedState exposing (SharedState)
import TW
import UI
import UI.Button


chapter_ : Chapter x
chapter_ =
    chapter "Form Controls"
        |> renderComponentList
            [ ( "Text input"
              , Html.input
                    [ UI.formTextInputAttr
                    , Attr.type_ "text"
                    , Attr.placeholder "Type something…"
                    ]
                    []
              )
            , ( "Audit-filter text input (full-width)"
              , Html.input
                    [ UI.formTextInputAuditFilterAttr
                    , Attr.type_ "text"
                    , Attr.placeholder "Filter…"
                    ]
                    []
              )
            , ( "Host-admin slug input (monospace)"
              , Html.input
                    [ UI.formTextInputHostAdminSlugAttr
                    , Attr.type_ "text"
                    , Attr.placeholder "my-wiki-slug"
                    ]
                    []
              )
            , ( "button (primary)"
              , UI.Button.button [] [ Html.text "Save changes" ]
              )
            , ( "button (disabled)"
              , UI.Button.button [ Attr.disabled True ] [ Html.text "Save changes" ]
              )
            , ( "dangerButton"
              , UI.Button.dangerButton [] [ Html.text "Delete page" ]
              )
            , ( "dangerButton (disabled)"
              , UI.Button.dangerButton [ Attr.disabled True ] [ Html.text "Delete page" ]
              )
            , ( "formCenteredCard — auth / login card"
              , Html.div [ UI.formCenteredCardAttr ]
                    [ Html.p [ TW.cls "m-0 mb-3 font-semibold text-[1.1rem] text-[var(--fg)]" ]
                        [ Html.text "Sign in" ]
                    , UI.contentLabel [] [ Html.text "Email" ]
                    , Html.input
                        [ UI.formTextInputAttr
                        , Attr.type_ "email"
                        , Attr.placeholder "you@example.com"
                        , Attr.style "width" "100%"
                        ]
                        []
                    , Html.div [ TW.cls "mt-3" ]
                        [ UI.Button.button [ Attr.style "width" "100%" ] [ Html.text "Continue" ] ]
                    ]
              )
            ]


chapterChips : Chapter SharedState
chapterChips =
    chapter "Togglable Chips"
        |> renderStatefulComponentList
            [ ( "off → click to toggle on"
              , \state ->
                    UI.Button.toggleChip []
                        { pressed = state.chip1
                        , onClick = ElmBook.Actions.updateState (\s -> { s | chip1 = not s.chip1 })
                        , label = "Elm"
                        }
              )
            , ( "on by default → click to toggle off"
              , \state ->
                    UI.Button.toggleChip []
                        { pressed = state.chip2
                        , onClick = ElmBook.Actions.updateState (\s -> { s | chip2 = not s.chip2 })
                        , label = "Haskell"
                        }
              )
            , ( "group of chips (all interactive)"
              , \state ->
                    Html.div [ TW.cls "flex flex-wrap gap-2" ]
                        [ UI.Button.toggleChip []
                            { pressed = state.chip1
                            , onClick = ElmBook.Actions.updateState (\s -> { s | chip1 = not s.chip1 })
                            , label = "Elm"
                            }
                        , UI.Button.toggleChip []
                            { pressed = state.chip2
                            , onClick = ElmBook.Actions.updateState (\s -> { s | chip2 = not s.chip2 })
                            , label = "Haskell"
                            }
                        , UI.Button.toggleChip []
                            { pressed = state.chip3
                            , onClick = ElmBook.Actions.updateState (\s -> { s | chip3 = not s.chip3 })
                            , label = "Rust"
                            }
                        ]
              )
            ]
