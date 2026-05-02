module Chapters.WikiComponents exposing (chapter_)

import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Html
import Html.Attributes as Attr
import TW
import UI
import UI.Link
import UI.Heading


chapter_ : Chapter x
chapter_ =
    chapter "Wiki Components"
        |> renderComponentList
            [ ( "tagPill — slug exists (clickable)"
              , Html.a [ UI.tagPillAttr True, Attr.href "#" ]
                    [ Html.text "functional-programming" ]
              )
            , ( "tagPill — slug missing (greyed out, cursor-default)"
              , Html.span [ UI.tagPillAttr False ]
                    [ Html.text "unknown-tag" ]
              )
            , ( "Tag pills list (tagPillsListAttr)"
              , Html.ul [ UI.tagPillsListAttr ]
                    [ Html.li [] [ Html.a [ UI.tagPillAttr True, Attr.href "#" ] [ Html.text "elm" ] ]
                    , Html.li [] [ Html.a [ UI.tagPillAttr True, Attr.href "#" ] [ Html.text "functional" ] ]
                    , Html.li [] [ Html.a [ UI.tagPillAttr True, Attr.href "#" ] [ Html.text "type-safety" ] ]
                    , Html.li [] [ Html.span [ UI.tagPillAttr False ] [ Html.text "missing-tag" ] ]
                    ]
              )
            , ( "Backlinks section"
              , Html.section [ UI.backlinksSectionAttr ]
                    [ UI.Heading.sidebarHeading "Backlinks"
                    , Html.ul [ UI.backlinksListAttr ]
                        [ UI.Link.listItemTight []
                            [ UI.Link.sidebarLink [ Attr.href "#" ] [ Html.text "Getting Started with Elm" ] ]
                        , UI.Link.listItemTight []
                            [ UI.Link.sidebarLink [ Attr.href "#" ] [ Html.text "The Elm Architecture" ] ]
                        , UI.Link.listItemTight []
                            [ UI.Link.missingLink [ Attr.href "#" ] [ Html.text "Missing Page (red)" ] ]
                        ]
                    ]
              )
            , ( "wikiCatalogCard"
              , Html.article [ UI.wikiCatalogCardAttr ]
                    [ Html.h3 [ UI.wikiCatalogCardTitleAttr ]
                        [ UI.Link.cardTitle [ Attr.href "#" ]
                            [ Html.text "The Elm Architecture"
                            , Html.em [ UI.wikiCatalogCardSlugEmAttr ]
                                [ Html.text " #the-elm-architecture" ]
                            ]
                        ]
                    , Html.p [ UI.wikiCatalogCardSummaryAttr ]
                        [ Html.text "A simple pattern for architecting web apps." ]
                    ]
              )
            , ( "wikiCatalogGrid (3-up grid)"
              , Html.div [ UI.wikiCatalogGridAttr ]
                    (List.map
                        (\( title, slug ) ->
                            Html.article [ UI.wikiCatalogCardAttr ]
                                [ Html.h3 [ UI.wikiCatalogCardTitleAttr ]
                                    [ UI.Link.cardTitle [ Attr.href "#" ]
                                        [ Html.text title
                                        , Html.em [ UI.wikiCatalogCardSlugEmAttr ]
                                            [ Html.text (" #" ++ slug) ]
                                        ]
                                    ]
                                , Html.p [ UI.wikiCatalogCardSummaryAttr ]
                                    [ Html.text "Short wiki description." ]
                                ]
                        )
                        [ ( "Elm Patterns", "elm-patterns" )
                        , ( "Functional Wiki", "functional-wiki" )
                        , ( "Type Systems", "type-systems" )
                        ]
                    )
              )
            , ( "todosListDiscAttr (compact todo disc list)"
              , Html.ol [ UI.todosListDiscAttr ]
                    [ Html.li [] [ Html.text "Fix the authentication flow" ]
                    , Html.li [] [ Html.text "Add search functionality" ]
                    , Html.li [] [ Html.text "Write integration tests" ]
                    ]
              )
            , ( "wikiRightRailTocNudgeAttr (negative-margin side inset)"
              , Html.div [ UI.wikiRightRailTocNudgeAttr, TW.cls "bg-[var(--chrome-bg)] p-2 text-[var(--fg-muted)] text-[0.8125rem]" ]
                    [ Html.text "Right-rail content with corrected side inset" ]
              )
            , ( "wikiRightRailSectionCardAttr (right-rail section wrapper)"
              , Html.div [ UI.wikiRightRailSectionCardAttr ]
                    [ Html.h3 [ TW.cls "m-0 mb-1 text-[0.8125rem] font-semibold text-[var(--fg-muted)]" ]
                        [ Html.text "Section Card" ]
                    , Html.p [ TW.cls "m-0 text-[0.8125rem] text-[var(--fg-muted)]" ]
                        [ Html.text "Rounded card shell for right-rail ToC/tags/backlinks sections." ]
                    ]
              )
            ]
