module ProgramTest.Story46_WikiLinksInMarkdown exposing (endToEndTests)

import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    List.concat
        [ ProgramTest.Start.bothViewports
            { baseName = "46 — [[Home]] on published page renders as same-wiki link"
            , config = ProgramTest.Config.demoWikiPagesOnly
            , sessionId = "session-wiki-links-about"
            , path = "/w/Demo/p/About"
            , connectClientMs = Nothing
            , clientSteps =
                \client ->
                    [ client.checkView 100
                        (ProgramTest.Query.withinId "page-markdown"
                            (ProgramTest.Query.withinHref "/w/Demo/p/Home"
                                (ProgramTest.Query.expectHasText "Home")
                            )
                        )
                    ]
            }
        , ProgramTest.Start.bothViewports
            { baseName = "46 — [[Návsí]] on published page keeps Unicode href"
            , config = ProgramTest.Config.demoWikiPagesOnly
            , sessionId = "session-wiki-links-diacritics"
            , path = "/w/Demo/p/MarkdownPlayground"
            , connectClientMs = Nothing
            , clientSteps =
                \client ->
                    [ client.checkView 100
                        (ProgramTest.Query.withinId "page-markdown"
                            (ProgramTest.Query.withinHref "/w/Demo/p/Návsí"
                                (ProgramTest.Query.expectHasText "Návsí")
                            )
                        )
                    ]
            }
        ]
