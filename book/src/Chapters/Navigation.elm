module Chapters.Navigation exposing (chapter_)

import ElmBook.Chapter exposing (Chapter, chapter, renderComponentList)
import Html
import Html.Attributes as Attr
import TW
import UI
import UI.Button
import UI.Link
import UI.Heading


chapter_ : Chapter x
chapter_ =
    chapter "Navigation & Sidebar"
        |> renderComponentList
            [ ( "sidebarHeading"
              , UI.Heading.sidebarHeading "Related Pages"
              )
            , ( "sidebarLink"
              , UI.Link.sidebarLink [ Attr.href "#" ] [ Html.text "Link to another page" ]
              )
            , ( "sidebarLink (ToC entry)"
              , UI.Link.sidebarLink [ Attr.href "#" ] [ Html.text "Table of Contents entry" ]
              )
            , ( "sideNavItemLink — normal"
              , UI.Link.navListItem False [ Attr.href "#" ] [ Html.text "Navigation item" ]
              )
            , ( "sideNavItemLink — emphasized (current page)"
              , UI.Link.navListItem True [ Attr.href "#" ] [ Html.text "Current page" ]
              )
            , ( "sideNavPublicAdminLink — normal"
              , UI.Link.navListItemMuted False [ Attr.href "#" ] [ Html.text "Admin" ]
              )
            , ( "sideNavPublicAdminLink — emphasized"
              , UI.Link.navListItemMuted True [ Attr.href "#" ] [ Html.text "Admin (emphasized)" ]
              )
            , ( "wikiSessionLogoutButton (button styled as link)"
              , UI.Button.inlineLinkButton [] [ Html.text "Sign out" ]
              )
            , ( "Full left-nav aside"
              , Html.aside [ UI.layoutLeftNavAsideAttr, Attr.style "width" "14rem" ]
                    [ Html.div [ UI.sideNavStackAttr ]
                        [ Html.nav [ UI.sideNavNavAttr ]
                            [ Html.ul [ UI.sideNavListAttr ]
                                [ Html.li []
                                    [ UI.Link.navListItem False [ Attr.href "#" ] [ Html.text "Home" ] ]
                                , Html.li []
                                    [ UI.Link.navListItem True [ Attr.href "#" ] [ Html.text "Current Page" ] ]
                                , Html.li []
                                    [ UI.Link.navListItemMuted False [ Attr.href "#" ] [ Html.text "Admin" ] ]
                                , Html.li []
                                    [ UI.Button.inlineLinkButton [] [ Html.text "Sign out" ] ]
                                ]
                            ]
                        ]
                    ]
              )
            , ( "Sidebar container — TOC section"
              , Html.div [ UI.sidebarContainerAttr, Attr.style "width" "14rem" ]
                    [ UI.Heading.sidebarHeading "Table of Contents"
                    , Html.div [ UI.sidebarNavSectionBodyAttr ]
                        [ Html.div [ UI.sidebarTocListRootAttr ]
                            [ Html.div [ TW.cls "flex flex-col gap-[0.25rem]" ]
                                [ UI.Link.sidebarLink [ Attr.href "#intro" ] [ Html.text "Introduction" ]
                                , UI.Link.sidebarLink [ Attr.href "#setup" ] [ Html.text "Setup" ]
                                , UI.Link.sidebarLink [ Attr.href "#usage" ] [ Html.text "Usage" ]
                                ]
                            ]
                        ]
                    , Html.div [ UI.pageActionsTopBorderBlockAttr ]
                        [ Html.div [ UI.pageActionsSidebarStackAttr ]
                            [ UI.Button.button [] [ Html.text "Edit page" ] ]
                        ]
                    ]
              )
            , ( "sidebarTocListIndent — nested TOC levels"
              , Html.div [ TW.cls "flex flex-col gap-[0.25rem]" ]
                    [ UI.Link.sidebarLink [ Attr.href "#h1" ] [ Html.text "Top-level heading" ]
                    , Html.div [ UI.sidebarTocListIndentAttr ]
                        [ UI.Link.sidebarLink [ Attr.href "#h2a" ] [ Html.text "Sub-heading A" ]
                        , UI.Link.sidebarLink [ Attr.href "#h2b" ] [ Html.text "Sub-heading B" ]
                        ]
                    ]
              )
            ]
