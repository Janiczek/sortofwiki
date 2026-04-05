module SideNavMenu exposing
    ( GlobalChromeInput
    , Link
    , Section
    , allLinks
    , globalChromeSections
    , wikiNavLinks
    )

import Route
import Wiki
import WikiRole exposing (WikiRole)


type alias Link =
    { linkLabel : String
    , linkRoute : Route.Route
    }


type alias Section =
    { sectionTitle : String
    , links : List Link
    }


type alias GlobalChromeInput =
    { hostAdminAuthenticated : Bool
    , showHostAdminTools : Bool
    }


{-| SortOfWiki + Host admin blocks (paths and labels match previous `Frontend` chrome).
-}
globalChromeSections : GlobalChromeInput -> List Section
globalChromeSections input =
    List.concat
        [ let
            sortOfWikiLinks : List Link
            sortOfWikiLinks =
                if input.hostAdminAuthenticated && input.showHostAdminTools then
                    []

                else if input.hostAdminAuthenticated then
                    [ { linkLabel = "Admin"
                      , linkRoute = Route.HostAdminWikis
                      }
                    ]

                else
                    [ { linkLabel = "Admin"
                      , linkRoute = Route.HostAdmin Nothing
                      }
                    ]
          in
          if List.isEmpty sortOfWikiLinks then
            []

          else
            [ { sectionTitle = "SortOfWiki"
              , links = sortOfWikiLinks
              }
            ]
        , if input.hostAdminAuthenticated && input.showHostAdminTools then
            [ { sectionTitle = "Host admin"
              , links =
                    [ { linkLabel = "Hosted wikis", linkRoute = Route.HostAdminWikis }
                    , { linkLabel = "Add wiki", linkRoute = Route.HostAdminWikiNew }
                    , { linkLabel = "Backup and restore", linkRoute = Route.HostAdminBackup }
                    , { linkLabel = "Audit log", linkRoute = Route.HostAdminAudit }
                    ]
              }
            ]

          else
            []
        ]


{-| Wiki-scoped sidebar routes only (excludes “Logged in as …” / log out).
-}
wikiNavLinks : Wiki.Slug -> Maybe WikiRole -> List Link
wikiNavLinks wikiSlug maybeRole =
    case maybeRole of
        Nothing ->
            [ { linkLabel = "Log in"
              , linkRoute = Route.WikiLogin wikiSlug Nothing
              }
            , { linkLabel = "Register"
              , linkRoute = Route.WikiRegister wikiSlug
              }
            ]

        Just role ->
            List.concat
                [ [ { linkLabel = "Create page"
                    , linkRoute = Route.WikiSubmitNew wikiSlug
                    }
                  ]
                    |> List.append
                        (if WikiRole.hasMySubmissionsAccess role then
                            [ { linkLabel = "My submissions"
                              , linkRoute = Route.WikiMySubmissions wikiSlug
                              }
                            ]

                         else
                            []
                        )
                , if WikiRole.isTrustedModerator role then
                    [ { linkLabel = "Review"
                      , linkRoute = Route.WikiReview wikiSlug
                      }
                    ]

                  else
                    []
                , if WikiRole.canAccessWikiAdminUsers role then
                    [ { linkLabel = "Admin"
                      , linkRoute = Route.WikiAdminUsers wikiSlug
                      }
                    , { linkLabel = "Audit log"
                      , linkRoute = Route.WikiAdminAudit wikiSlug
                      }
                    ]

                  else
                    []
                ]


allLinks : List Section -> List Link
allLinks sections =
    sections
        |> List.concatMap .links
