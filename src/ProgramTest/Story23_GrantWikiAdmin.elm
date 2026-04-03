module ProgramTest.Story23_GrantWikiAdmin exposing (endToEndTests)

import Effect.Browser.Dom
import ProgramTest.Config
import ProgramTest.Actions
import ProgramTest.Query
import ProgramTest.Start
import Wiki


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.startWith
        { name = "23 — admin grants grantadmin_trusted wiki admin; that user can open admin users"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , steps =
            [ ProgramTest.Start.connectFrontend
                { sessionId = "session-story23-admin-grant"
                , path = "/"
                , connectClientMs = Nothing
                , steps =
                    \client ->
                        List.concat
                            [ ProgramTest.Actions.loginToWiki
                                { wikiSlug = "Demo"
                                , username = "wikidemo"
                                , password = "password12"
                                }
                                client
                            , [ client.checkView 300
                                    (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                              , client.clickLink 100 (Wiki.adminUsersUrlPath "Demo")
                              , client.checkView 400
                                    (ProgramTest.Query.withinDataAttributes
                                        [ ( "data-target-username", "grantadmin_trusted" )
                                        , ( "data-context", "wiki-admin-grant-admin" )
                                        ]
                                        (ProgramTest.Query.expectHasText "Make admin")
                                    )
                              , client.click 100
                                    (Effect.Browser.Dom.id "wiki-admin-grant-admin-grantadmin_trusted")
                              , client.checkView 600
                                    (ProgramTest.Query.withinDataAttribute "data-admin-user" "grantadmin_trusted"
                                        (ProgramTest.Query.withinDataAttribute "data-user-role" "Admin"
                                            (ProgramTest.Query.expectHasText "Admin")
                                        )
                                    )
                              ]
                            ]
                }
            , ProgramTest.Start.connectFrontend
                { sessionId = "session-story23-new-admin"
                , path = "/"
                , connectClientMs = Nothing
                , steps =
                    \client ->
                        List.concat
                            [ ProgramTest.Actions.loginToWiki
                                { wikiSlug = "Demo"
                                , username = "grantadmin_trusted"
                                , password = "password12"
                                }
                                client
                            , [ client.checkView 300
                                    (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                              , client.clickLink 100 (Wiki.adminUsersUrlPath "Demo")
                              , client.checkView 500
                                    (ProgramTest.Query.expectPageShowsWikiSlug "wiki-admin-users-page" "Demo")
                              ]
                            ]
                }
            ]
        }
    ]
