module Chapters.PanelHeader exposing (chapter_)

import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Html
import TW
import UI.PanelHeader


chapter_ : Chapter x
chapter_ =
    chapter "UI.PanelHeader"
        |> renderComponentList
            [ ( "PanelHeader.h2 / h3 (editor shell)"
              , Html.div
                    [ TW.cls "flex flex-col max-w-md border border-[var(--border-subtle)] rounded-lg overflow-hidden bg-[var(--input-bg)]" ]
                    [ UI.PanelHeader.view { kind = UI.PanelHeader.Primary, text = "EDITOR" }
                    , UI.PanelHeader.view { kind = UI.PanelHeader.Secondary, text = "LIVE PREVIEW" }
                    , Html.div [ TW.cls "p-2 text-[0.85rem] text-[var(--fg-muted)]" ]
                        [ Html.text "Markdown / preview columns use this chrome." ]
                    ]
              )
            ]
