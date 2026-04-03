module ProgramTest.Story06_OnlyPublished exposing (endToEndTests)

import Expect
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Wiki


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "Pending edit not shown on /w/Demo/p/Home"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story06-home"
        , path = "/w/Demo/p/Home"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                [ client.checkView 100
                    (ProgramTest.Query.expectAll
                        [ ProgramTest.Query.withinId "page-markdown"
                            (ProgramTest.Query.expectHasText "Welcome to the Demo Wiki")
                        , ProgramTest.Query.expectHasNotText "STORY06_PENDING_LEAK"
                        , ProgramTest.Query.expectHasNotText "STORY06_PENDING_ONLY"
                        ]
                    )
                ]
        }
    , ProgramTest.Start.start
        { name = "Pending new page not in list, shows 404 at /w/Demo/p/OnlyPending"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story06-pending-only"
        , path = "/w/Demo/p/OnlyPending"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                [ client.checkView 100
                    (ProgramTest.Query.expectAll
                        [ ProgramTest.Query.withinLayoutHeader
                            (ProgramTest.Query.expectAll
                                [ ProgramTest.Query.expectHasText ": Create?"
                                , ProgramTest.Query.expectHasText "OnlyPending"
                                ]
                            )
                        , ProgramTest.Query.expectHasNotText "STORY06_PENDING_ONLY"
                        ]
                    )
                , client.clickLink 100 (Wiki.wikiHomeUrlPath "Demo")
                , client.checkView 100
                    (ProgramTest.Query.withinId "wiki-home-page-slugs"
                        (ProgramTest.Query.expectDataAttributeOccurrenceCount "data-page-slug"
                            "OnlyPending"
                            (Expect.equal 0)
                        )
                    )
                ]
        }
    ]
