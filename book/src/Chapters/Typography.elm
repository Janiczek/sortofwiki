module Chapters.Typography exposing (chapter_)

import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Html
import Html.Attributes as Attr
import UI
import UI.Heading
import UI.Link


chapter_ : Chapter x
chapter_ =
    chapter "Typography"
        |> renderComponentList
            [ ( "contentLink"
              , UI.Link.contentLink [ Attr.href "#" ] [ Html.text "A content link" ]
              )
            , ( "contentLinkWithBold — normal weight"
              , UI.Link.contentLink [ Attr.href "#" ] [ Html.text "Normal-weight link" ]
              )
            , ( "contentLinkWithBold — bold"
              , UI.Link.contentLink [ Attr.href "#", Attr.style "font-weight" "700" ] [ Html.text "Bold-weight link" ]
              )
            , ( "contentHeading2"
              , UI.Heading.contentHeading2 [] [ Html.text "A Content Heading" ]
              )
            , ( "contentParagraph"
              , UI.contentParagraph []
                    [ Html.text "This is a content paragraph. It uses the serif font for body-copy style rendering, with comfortable spacing and line-height from the design system." ]
              )
            , ( "contentLabel"
              , UI.contentLabel [] [ Html.text "Form field label" ]
              )
            ]
