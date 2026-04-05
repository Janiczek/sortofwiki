module ProgramTest.Story20_AdminUsers exposing (endToEndTests)

import ProgramTest.Actions
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Wiki


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "20 — wiki admin opens /w/Demo/admin/users and sees contributors"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story20-admin-users"
        , path = "/"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                List.concat
                    [ ProgramTest.Actions.loginToWiki
                        { wikiSlug = "Demo"
                        , username = "demo_wiki_admin"
                        , password = "password12"
                        }
                        client
                    , [ client.checkView 300
                            (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      , client.clickLink 100 (Wiki.adminUsersUrlPath "Demo")
                      , client.checkView 500
                            (ProgramTest.Query.expectPageShowsWikiSlug "wiki-admin-users-page" "Demo")
                      , client.checkView 100
                            (ProgramTest.Query.expectAll
                                [ ProgramTest.Query.withinDataAttribute "data-admin-user"
                                    "demo_contributor"
                                    (ProgramTest.Query.expectHasText "demo_contributor")
                                , ProgramTest.Query.withinDataAttribute "data-admin-user"
                                    "demo_trusted_publisher"
                                    (ProgramTest.Query.expectHasText "demo_trusted_publisher")
                                , ProgramTest.Query.withinDataAttribute "data-admin-user"
                                    "demo_wiki_admin"
                                    (ProgramTest.Query.expectHasText "demo_wiki_admin")
                                ]
                            )
                      ]
                    ]
        }
    ]
