module ProgramTest.Story05_Backlinks exposing (endToEndTests)

import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "5 — backlinks on published page /w/Demo/p/Guides"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-backlinks-guides"
        , path = "/w/Demo/p/Guides"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                [ client.checkView 100
                    (ProgramTest.Query.expectAll
                        [ ProgramTest.Query.withinId "page-backlinks"
                            (ProgramTest.Query.expectHasText "Backlinks")
                        , ProgramTest.Query.withinId "page-backlinks-list"
                            (ProgramTest.Query.withinHref "/w/Demo/p/Home"
                                (ProgramTest.Query.expectHasDataAttributes [ ( "data-backlink-page-slug", "Home" ) ])
                            )
                        ]
                    )
                ]
        }
    , ProgramTest.Start.start
        { name = "5 — backlinks on home list pages that link here (about → home, not reciprocated)"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-backlinks-home"
        , path = "/w/Demo/p/Home"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                [ client.checkView 100
                    (ProgramTest.Query.withinId "page-backlinks-list"
                        (ProgramTest.Query.withinHref "/w/Demo/p/About"
                            (ProgramTest.Query.expectHasDataAttributes [ ( "data-backlink-page-slug", "About" ) ])
                        )
                    )
                ]
        }
    , ProgramTest.Start.start
        { name = "5 — backlinks empty state on single-page wiki /w/ElmTips/p/Home"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-backlinks-elm-tips-home"
        , path = "/w/ElmTips/p/Home"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                [ client.checkView 100
                    (ProgramTest.Query.withinId "page-backlinks"
                        (ProgramTest.Query.expectHasText "No backlinks.")
                    )
                ]
        }
    ]
