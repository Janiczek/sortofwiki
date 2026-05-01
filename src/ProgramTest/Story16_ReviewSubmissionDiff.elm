module ProgramTest.Story16_ReviewSubmissionDiff exposing (endToEndTests)

import ProgramTest.Actions
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Wiki


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    ProgramTest.Start.bothViewports
        { baseName = "16 — trusted contributor sees submission diff on review detail"
        , config = ProgramTest.Config.demoWikiWithModerationSeeds
        , sessionId = "session-story16-review-diff"
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
                      , client.clickLink 100 (Wiki.reviewDetailUrlPath "Demo" "sub_1")
                      , client.checkView 500
                            (ProgramTest.Query.withinIds
                                [ "wiki-review-detail-page"
                                , "wiki-review-diff-summary"
                                , "wiki-review-diff-new"
                                ]
                                (ProgramTest.Query.expectHasInputValue
                                    "Seeded pending submission for the trusted review queue."
                                )
                            )
                      ]
                    ]
        }
