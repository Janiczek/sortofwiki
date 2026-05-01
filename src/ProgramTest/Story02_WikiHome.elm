module ProgramTest.Story02_WikiHome exposing (endToEndTests)

import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    List.concat
        [ ProgramTest.Start.bothViewports
        { baseName = "See wiki home on /w/:wiki"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-wiki-demo"
        , path = "/w/Demo"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                [ client.checkView 200
                    (ProgramTest.Query.expectHasText "Demo Wiki")
                , client.checkView 100
                    (ProgramTest.Query.withinId "wiki-home-page"
                        (ProgramTest.Query.expectHasText "Pages")
                    )
                ]
        }
    , ProgramTest.Start.bothViewports
        { baseName = "See 'Wiki not found' on /w/unknown"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-wiki-unknown"
        , path = "/w/unknown-slug"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                [ client.checkView 100
                    (ProgramTest.Query.expectAll
                        [ ProgramTest.Query.withinLayoutHeader (ProgramTest.Query.expectHasText "Wiki not found")
                        , ProgramTest.Query.withinId "wiki-not-found-page"
                            (ProgramTest.Query.expectHasTexts
                                [ "The wiki "
                                , "unknown-slug"
                                , " doesn't exist."
                                ]
                            )
                        ]
                    )
                ]
        }
        ]
