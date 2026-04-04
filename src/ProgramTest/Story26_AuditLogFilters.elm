module ProgramTest.Story26_AuditLogFilters exposing (endToEndTests)

import Effect.Browser.Dom
import Expect
import ProgramTest.Config
import ProgramTest.Actions
import ProgramTest.Query
import ProgramTest.Start
import Wiki


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "26 — wiki admin filters audit log by event type"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story26-audit-filters"
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
                            (ProgramTest.Query.withinId "wiki-admin-promote-trusted-statusdemo"
                                (ProgramTest.Query.expectHasText "Promote")
                            )
                      , client.click 100 (Effect.Browser.Dom.id "wiki-admin-promote-trusted-statusdemo")
                      , client.checkView 600
                            (ProgramTest.Query.withinId "wiki-admin-users-page"
                                (ProgramTest.Query.expectHasText "statusdemo")
                            )
                      , client.click 100 (Effect.Browser.Dom.id "wiki-admin-grant-admin-grantadmin_trusted")
                      , client.checkView 600
                            (ProgramTest.Query.withinId "wiki-admin-users-page"
                                (ProgramTest.Query.expectHasText "grantadmin_trusted")
                            )
                      , client.clickLink 100 (Wiki.adminAuditUrlPath "Demo")
                      , client.checkView 600
                            (ProgramTest.Query.withinId "wiki-admin-audit-tbody"
                                (ProgramTest.Query.expectTagOccurrenceCount "tr"
                                    (\n ->
                                        if n >= 2 then
                                            Expect.pass

                                        else
                                            Expect.fail ("expected at least 2 audit rows before filter, got " ++ String.fromInt n)
                                    )
                                )
                            )
                      , client.click 100 (Effect.Browser.Dom.id "wiki-admin-audit-filter-type-granted_wiki_admin")
                      , client.checkView 600
                            (ProgramTest.Query.withinId "wiki-admin-audit-tbody"
                                (ProgramTest.Query.expectTagOccurrenceCount "tr" (\c -> c |> Expect.equal 1))
                            )
                      , client.checkView 100
                            (ProgramTest.Query.withinAuditEventIndex "0"
                                (ProgramTest.Query.expectHasText "Granted wiki admin to grantadmin_trusted")
                            )
                      ]
                    ]
        }
    ]
