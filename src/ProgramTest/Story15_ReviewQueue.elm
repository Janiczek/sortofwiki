module ProgramTest.Story15_ReviewQueue exposing (endToEndTests)

import ProgramTest.Actions
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Wiki


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "15 — trusted contributor sees standard user's pending submission in review queue"
        , config = ProgramTest.Config.demoWikiWithModerationSeeds
        , sessionId = "session-story15-review-queue"
        , path = "/"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                List.concat
                    [ ProgramTest.Actions.loginToWiki
                        { wikiSlug = "Demo"
                        , username = "demo_trusted_publisher"
                        , password = "password12"
                        }
                        client
                    , [ client.checkView 300
                            (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      , client.clickLink 100 (Wiki.reviewQueueUrlPath "Demo")
                      , client.checkView 400
                            (ProgramTest.Query.withinId "wiki-review-queue-page"
                                (ProgramTest.Query.withinDataAttribute "data-submission-id"
                                    "sub_1"
                                    (ProgramTest.Query.expectHasText "demo_contributor")
                                )
                            )
                      , client.checkView 100
                            (ProgramTest.Query.withinAriaLabel "Wiki"
                                (ProgramTest.Query.withinLinkHref (Wiki.reviewQueueUrlPath "Demo")
                                    (ProgramTest.Query.expectAll
                                        [ ProgramTest.Query.expectHasText "Review (2)"
                                        , ProgramTest.Query.expectHasClass "font-bold"
                                        ]
                                    )
                                )
                            )
                      ]
                    ]
        }
    ]
