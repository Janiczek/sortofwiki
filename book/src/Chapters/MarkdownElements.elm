module Chapters.MarkdownElements exposing (chapter_)

import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Html
import Html.Attributes as Attr
import UI
import UI.Link
import UI.Heading
import UI.Textarea


chapter_ : Chapter x
chapter_ =
    chapter "Markdown Elements"
        |> renderComponentList
            [ ( "Headings h1–h6 (inside markdownContainerClass)"
              , Html.div [ UI.markdownContainerAttr ]
                    [ UI.Heading.markdownHeading1 [] [ Html.text "Heading 1" ]
                    , UI.Heading.markdownHeading2 [] [ Html.text "Heading 2" ]
                    , UI.Heading.markdownHeading3 [] [ Html.text "Heading 3" ]
                    , UI.Heading.markdownHeading4 [] [ Html.text "Heading 4" ]
                    , UI.Heading.markdownHeading5 [] [ Html.text "Heading 5" ]
                    , UI.Heading.markdownHeading6 [] [ Html.text "Heading 6" ]
                    ]
              )
            , ( "markdownParagraphClass"
              , Html.p [ UI.markdownParagraphAttr ]
                    [ Html.text "A paragraph of body text. It uses a serif typeface and comfortable line-height, reading naturally at medium column widths." ]
              )
            , ( "markdownUnorderedListClass / markdownListItemClass"
              , Html.ul [ UI.markdownUnorderedListAttr ]
                    [ Html.li [ UI.markdownListItemAttr ] [ Html.text "First item" ]
                    , Html.li [ UI.markdownListItemAttr ] [ Html.text "Second item" ]
                    , Html.li [ UI.markdownListItemAttr ] [ Html.text "Third item" ]
                    ]
              )
            , ( "markdownOrderedListClass"
              , Html.ol [ UI.markdownOrderedListAttr ]
                    [ Html.li [ UI.markdownListItemAttr ] [ Html.text "Step one" ]
                    , Html.li [ UI.markdownListItemAttr ] [ Html.text "Step two" ]
                    , Html.li [ UI.markdownListItemAttr ] [ Html.text "Step three" ]
                    ]
              )
            , ( "markdownCodeSpanClass"
              , Html.p []
                    [ Html.text "Run "
                    , Html.code [ UI.markdownCodeSpanAttr ] [ Html.text "elm make src/Main.elm" ]
                    , Html.text " to compile."
                    ]
              )
            , ( "markdownCodeBlockPreClass / markdownCodeBlockCodeClass"
              , Html.pre [ UI.markdownCodeBlockPreAttr ]
                    [ Html.code [ UI.markdownCodeBlockCodeAttr ]
                        [ Html.text "main =\n    Browser.sandbox\n        { init = init\n        , update = update\n        , view = view\n        }" ]
                    ]
              )
            , ( "markdownTextareaClass (source editor)"
              , Html.textarea
                    (UI.Textarea.markdownEditableCell [ Attr.rows 6 ])
                    [ Html.text "# Heading\n\nSome **bold** and *italic* text.\n\n- item 1\n- item 2" ]
              )
            , ( "markdownBlockQuoteClass"
              , Html.blockquote [ UI.markdownBlockQuoteAttr ]
                    [ Html.text "This is a blockquote with a left border and muted text color." ]
              )
            , ( "markdownThematicBreakClass"
              , Html.div []
                    [ Html.p [] [ Html.text "Content above the break." ]
                    , Html.hr [ UI.markdownThematicBreakAttr ] []
                    , Html.p [] [ Html.text "Content below the break." ]
                    ]
              )
            , ( "UI.Link.contentLink (markdown/content link style)"
              , Html.p []
                    [ UI.Link.contentLink [ Attr.href "#" ] [ Html.text "An in-document wiki link" ] ]
              )
            , ( "UI.Link.missingLink (red, broken link)"
              , Html.p []
                    [ UI.Link.missingLink [ Attr.href "#" ] [ Html.text "[[Missing Page]]" ] ]
              )
            , ( "markdownWikiLinkMissingWithGridAttr (grid-positioned variant)"
              , Html.div [ UI.classAttr "grid grid-cols-2 gap-2" ]
                    [ UI.Link.missingLink
                        [ UI.classAttr "col-start-1 row-start-1"
                        , Attr.href "#"
                        ]
                        [ Html.text "[[Missing col 1]]" ]
                    , UI.Link.missingLink
                        [ UI.classAttr "col-start-2 row-start-1"
                        , Attr.href "#"
                        ]
                        [ Html.text "[[Missing col 2]]" ]
                    ]
              )
            , ( "markdownTodoClass (italic red)"
              , Html.p [ UI.markdownTodoAttr ]
                    [ Html.text "TODO: finish this section" ]
              )
            , ( "markdownTableClass — full markdown table"
              , Html.table [ UI.markdownTableAttr ]
                    [ Html.thead []
                        [ Html.tr [ UI.markdownTableRowAttr ]
                            [ Html.th [ UI.markdownTableHeaderCellAttr ] [ Html.text "Column A" ]
                            , Html.th [ UI.markdownTableHeaderCellAttr ] [ Html.text "Column B" ]
                            ]
                        ]
                    , Html.tbody []
                        [ Html.tr [ UI.markdownTableRowAttr ]
                            [ Html.td [ UI.markdownTableCellAttr ] [ Html.text "Row 1, A" ]
                            , Html.td [ UI.markdownTableCellAttr ] [ Html.text "Row 1, B" ]
                            ]
                        , Html.tr [ UI.markdownTableRowAttr ]
                            [ Html.td [ UI.markdownTableCellAttr ] [ Html.text "Row 2, A" ]
                            , Html.td [ UI.markdownTableCellAttr ] [ Html.text "Row 2, B" ]
                            ]
                        ]
                    ]
              )
            , ( "markdownPreviewScrollClass (bounded scroll area)"
              , Html.div [ UI.classAttr UI.markdownPreviewScrollClass ]
                    [ Html.div [ UI.markdownContainerAttr ]
                        [ UI.Heading.markdownHeading2 [] [ Html.text "Preview" ]
                        , Html.p [ UI.markdownParagraphAttr ]
                            [ Html.text "This container has a max-height and overflow-y scroll." ]
                        , Html.p [ UI.markdownParagraphAttr ]
                            [ Html.text "More content follows below." ]
                        ]
                    ]
              )
            ]
