module ProgramTest.Story52_HostAdminWikiBackup exposing (endToEndTests)

import Effect.Browser.Dom
import Env
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "52 — host admin per-wiki JSON backup buttons on /admin/wikis"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story52-wiki-backup"
        , path = "/admin"
        , connectClientMs = Just 200
        , clientSteps =
            \client ->
                [ client.input 100 (Effect.Browser.Dom.id "host-admin-login-password") Env.hostAdminPassword
                , client.click 100 (Effect.Browser.Dom.id "host-admin-login-submit")
                , client.checkView 300
                    (ProgramTest.Query.withinHostAdminWikiRow "Demo"
                        (ProgramTest.Query.expectHasText "Export JSON")
                    )
                , client.checkView 100
                    (ProgramTest.Query.withinHostAdminWikiRow "Demo"
                        (ProgramTest.Query.expectHasText "Import JSON…")
                    )
                ]
        }
    ]
