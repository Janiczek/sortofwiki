module Chapters.SidebarSection exposing (chapter_)

import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Html
import TW
import UI.EmptyState
import UI.SidebarSection


chapter_ : Chapter x
chapter_ =
    chapter "UI.SidebarSection"
        |> renderComponentList
            [ ( "SidebarSection.section"
              , Html.div [ TW.cls "max-w-[14rem]" ]
                    [ UI.SidebarSection.section
                        { id = "book-sidebar-demo"
                        , title = "Backlinks"
                        , body =
                            UI.EmptyState.paragraph
                                { id = "book-sidebar-empty"
                                , text = "No backlinks."
                                }
                        }
                    ]
              )
            ]
