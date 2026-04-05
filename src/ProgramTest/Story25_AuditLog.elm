module ProgramTest.Story25_AuditLog exposing (endToEndTests)

import Effect.Browser.Dom
import ProgramTest.Actions
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Wiki


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "Audit log"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story25-audit"
        , path = "/"
        , connectClientMs = Nothing
        , clientSteps =
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
                            (ProgramTest.Query.withinId "wiki-admin-grant-admin-grantadmin_trusted"
                                (ProgramTest.Query.expectHasText "Make admin")
                            )
                      , client.click 100 (Effect.Browser.Dom.id "wiki-admin-grant-admin-grantadmin_trusted")
                      , client.checkView 600
                            (ProgramTest.Query.withinId "wiki-admin-users-page"
                                (ProgramTest.Query.expectHasText "grantadmin_trusted")
                            )
                      , client.clickLink 100 (Wiki.adminAuditUrlPath "Demo")
                      , client.checkView 600
                            (ProgramTest.Query.withinId "wiki-admin-audit-list"
                                (ProgramTest.Query.expectHasTexts
                                    [ "wikidemo"
                                    , "Granted wiki admin to grantadmin_trusted"
                                    ]
                                )
                            )
                      ]
                    ]
        }
    ]
