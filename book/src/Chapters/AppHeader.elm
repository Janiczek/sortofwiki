module Chapters.AppHeader exposing (chapter_)

import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Html
import Html.Attributes as Attr
import UI
import UI.Button
import UI.Link


chapter_ : Chapter x
chapter_ =
    chapter "App Header"
        |> renderComponentList
            [ ( "appHeaderBar — wiki page with secondary bracket"
              , Html.header [ UI.appHeaderBarAttr ]
                    [ Html.h1 [ UI.appHeaderH1Attr ]
                        [ Html.div [ UI.appHeaderTitleRowAttr ]
                            [ UI.Link.navPrimary [ Attr.href "#" ] [ Html.text "My Wiki" ]
                            , Html.div [ UI.appHeaderDividerAttr ] []
                            , Html.span [ UI.appHeaderSecondaryWikiWrapAttr ]
                                [ Html.span [ UI.appHeaderSecondaryBracketAttr ]
                                    [ Html.text "[" ]
                                , Html.span [ UI.appHeaderSecondaryAfterDividerAttr ]
                                    [ Html.text "Getting Started" ]
                                , Html.span [ UI.appHeaderSecondaryBracketAttr ]
                                    [ Html.text "]" ]
                                ]
                            ]
                        ]
                    , UI.Button.iconGhostButton [] [ Html.text "☀" ]
                    ]
              )
            , ( "appHeaderBar — plain title (admin page, no link)"
              , Html.header [ UI.appHeaderBarAttr ]
                    [ Html.h1 [ UI.appHeaderH1Attr ]
                        [ Html.span [ UI.appHeaderPrimaryPlainAttr ]
                            [ Html.text "Host Admin" ]
                        ]
                    ]
              )
            , ( "appHeaderBar — wiki title with em label"
              , Html.header [ UI.appHeaderBarAttr ]
                    [ Html.h1 [ UI.appHeaderH1Attr ]
                        [ Html.div [ UI.appHeaderTitleRowAttr ]
                            [ UI.Link.navPrimary [ Attr.href "#" ] [ Html.text "My Wiki" ]
                            , Html.div [ UI.appHeaderDividerAttr ] []
                            , Html.span [ UI.appHeaderSecondaryMetaAttr ]
                                [ Html.em [ UI.appHeaderSecondaryWikiLabelEmAttr ]
                                    [ Html.text "a wiki about " ]
                                , Html.text "Functional Programming"
                                ]
                            ]
                        ]
                    , UI.Button.iconGhostButton [] [ Html.text "☀" ]
                    ]
              )
            ]
