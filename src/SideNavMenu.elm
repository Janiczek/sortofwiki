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
    , linkEmphasized : Bool
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
                      , linkEmphasized = False
                      }
                    ]

                else
                    [ { linkLabel = "Admin"
                      , linkRoute = Route.HostAdmin Nothing
                      , linkEmphasized = False
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
                    [ { linkLabel = "Hosted wikis", linkRoute = Route.HostAdminWikis, linkEmphasized = False }
                    , { linkLabel = "Add wiki", linkRoute = Route.HostAdminWikiNew, linkEmphasized = False }
                    , { linkLabel = "Backup and restore", linkRoute = Route.HostAdminBackup, linkEmphasized = False }
                    , { linkLabel = "Audit log", linkRoute = Route.HostAdminAudit, linkEmphasized = False }
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
    let
        publicLinks : List Link
        publicLinks =
            [ { linkLabel = "Graph"
              , linkRoute = Route.WikiGraph wikiSlug
              , linkEmphasized = False
              }
            , { linkLabel = "TODOs"
              , linkRoute = Route.WikiTodos wikiSlug
              , linkEmphasized = False
              }
            ]
    in
    case maybeRole of
        Nothing ->
            publicLinks
                ++ [ { linkLabel = "Log in"
                     , linkRoute = Route.WikiLogin wikiSlug Nothing
                     , linkEmphasized = False
                     }
                   , { linkLabel = "Register"
                     , linkRoute = Route.WikiRegister wikiSlug
                     , linkEmphasized = False
                     }
                   ]

        Just role ->
            publicLinks
                ++ List.concat
                    [ [ { linkLabel = "Create page"
                        , linkRoute = Route.WikiSubmitNew wikiSlug
                        , linkEmphasized = False
                        }
                      ]
                        |> List.append
                            (if WikiRole.hasMySubmissionsAccess role then
                                [ { linkLabel = "My submissions"
                                  , linkRoute = Route.WikiMySubmissions wikiSlug
                                  , linkEmphasized = False
                                  }
                                ]

                             else
                                []
                            )
                    , if WikiRole.isTrustedModerator role then
                        [ { linkLabel = "Review"
                          , linkRoute = Route.WikiReview wikiSlug
                          , linkEmphasized = False
                          }
                        ]

                      else
                        []
                    , if WikiRole.canAccessWikiAdminUsers role then
                        [ { linkLabel = "Admin"
                          , linkRoute = Route.WikiAdminUsers wikiSlug
                          , linkEmphasized = False
                          }
                        , { linkLabel = "Audit log"
                          , linkRoute = Route.WikiAdminAudit wikiSlug
                          , linkEmphasized = False
                          }
                        ]

                      else
                        []
                    ]


allLinks : List Section -> List Link
allLinks sections =
    sections
        |> List.concatMap .links
