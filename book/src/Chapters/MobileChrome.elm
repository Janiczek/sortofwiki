module Chapters.MobileChrome exposing (chapter_)

import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Html
import Html.Attributes as Attr
import TW
import UI.MobileChrome


chapter_ : Chapter x
chapter_ =
    chapter "UI.MobileChrome"
        |> renderComponentList
            [ ( "UI.MobileChrome.menuButton"
              , UI.MobileChrome.menuButton [ Attr.attribute "aria-expanded" "false" ]
              )
            , ( "UI.MobileChrome.wikiSearchRouteLink"
              , UI.MobileChrome.wikiSearchRouteLink
                    [ Attr.href "/w/Demo/search" ]
                    [ Html.text "Search" ]
              )
            , ( "combined strip"
              , Html.div [ TW.cls "flex items-center gap-2 bg-[var(--chrome-bg)] p-2" ]
                    [ UI.MobileChrome.menuButton [ Attr.attribute "aria-expanded" "false" ]
                    , Html.div [ TW.cls "flex-1 text-[0.75rem] text-[var(--fg-muted)]" ] [ Html.text "header row preview" ]
                    , UI.MobileChrome.wikiSearchRouteLink
                        [ Attr.href "/w/Demo/search" ]
                        [ Html.text "Search" ]
                    ]
              )
            ]
