module ProgramTest.Story35_NotFound exposing (endToEndTests)

import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    ProgramTest.Start.bothViewports
        { baseName = "35 — 404 for unknown URL"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-404"
        , path = "/no-such-page"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                [ client.checkView 100
                    (ProgramTest.Query.withinLayoutHeader (ProgramTest.Query.expectHasText "Page not found"))
                ]
        }
