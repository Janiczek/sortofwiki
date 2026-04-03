module ProgramTest.Story01_WikiList exposing (endToEndTests)

import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Wiki


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "See list of wikis on /"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-anonymous-viewer"
        , path = "/"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                [ client.checkView 100
                    (ProgramTest.Query.expectAll
                        [ ProgramTest.Query.headingIs "SortOfWiki"
                        , ProgramTest.Query.subheadingIs "Wikis"
                        , ProgramTest.Query.withinLayoutHeader
                            (ProgramTest.Query.expectLink
                                { href = Wiki.wikiListUrlPath
                                , label = "SortOfWiki"
                                }
                            )
                        , ProgramTest.Query.expectWikiCard { slug = "Demo", title = "Demo Wiki" }
                        , ProgramTest.Query.expectWikiCard { slug = "ElmTips", title = "Elm Tips" }
                        ]
                    )
                ]
        }
    ]
