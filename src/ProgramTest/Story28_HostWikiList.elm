module ProgramTest.Story28_HostWikiList exposing (endToEndTests)

import Effect.Browser.Dom
import Env
import ProgramTest.Actions
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "28 — host admin wiki list /admin/wikis"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story28-host-wikis"
        , path = "/admin"
        , connectClientMs = Just 200
        , clientSteps =
            \client ->
                List.concat
                    [ [ client.input 100 (Effect.Browser.Dom.id "host-admin-login-password") Env.hostAdminPassword
                      ]
                    , ProgramTest.Actions.triggerFormSubmit "host-admin-login-form" client
                    , [ client.checkView 300
                            (ProgramTest.Query.withinId "host-admin-wikis-list"
                                ProgramTest.Query.expectEmpty
                            )
                      , client.checkView 100
                            (ProgramTest.Query.expectAll
                                [ ProgramTest.Query.withinHostAdminWikiRow "Demo"
                                    (ProgramTest.Query.expectHasText "Demo Wiki")
                                , ProgramTest.Query.withinHostAdminWikiRow "ElmTips"
                                    (ProgramTest.Query.expectHasText "Elm Tips")
                                ]
                            )
                      ]
                    ]
        }
    ]
