module ProgramTest.Story51_HostAdminAuditLog exposing (endToEndTests)

import Effect.Browser.Dom
import Env
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Wiki


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "51 — host admin platform audit log"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story51-host-audit"
        , path = "/admin"
        , connectClientMs = Just 200
        , clientSteps =
            \client ->
                [ client.input 100 (Effect.Browser.Dom.id "host-admin-login-password") Env.hostAdminPassword
                , client.click 100 (Effect.Browser.Dom.id "host-admin-login-submit")
                , client.checkView 400
                    (ProgramTest.Query.withinId "host-admin-wikis-list"
                        (ProgramTest.Query.expectHasText "Demo")
                    )
                , client.clickLink 100 Wiki.hostAdminAuditUrlPath
                , client.checkView 500
                    (ProgramTest.Query.withinId "host-admin-audit-list"
                        (ProgramTest.Query.expectHasTexts
                            [ "Demo"
                            , "ElmTips"
                            , "wikidemo"
                            , "Promoted contributor"
                            ]
                        )
                    )
                ]
        }
    ]
