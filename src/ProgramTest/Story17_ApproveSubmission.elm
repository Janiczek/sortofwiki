module ProgramTest.Story17_ApproveSubmission exposing (endToEndTests)

import Effect.Browser.Dom
import ProgramTest.Actions
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Wiki


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "17 — trusted contributor approves pending new-page submission; page goes live"
        , config = ProgramTest.Config.demoWikiWithModerationSeeds
        , sessionId = "session-story17-approve"
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
                      , client.checkView 400
                            (ProgramTest.Query.withinId "wiki-review-decision-submit"
                                (ProgramTest.Query.expectHasText "Submit")
                            )
                      , client.click 100 (Effect.Browser.Dom.id "wiki-review-decision-submit")
                      , client.checkView 500
                            (ProgramTest.Query.withinId "wiki-review-approve-success"
                                (ProgramTest.Query.expectHasText "Submission approved and published.")
                            )
                      , client.clickLink 100 (Wiki.wikiHomeUrlPath "Demo")
                      , client.clickLink 100 (Wiki.publishedPageUrlPath "Demo" "QueueDemoPage")
                      , client.checkView 400
                            (ProgramTest.Query.withinId "page-markdown"
                                (ProgramTest.Query.expectHasText
                                    "Seeded pending submission for the trusted review queue."
                                )
                            )
                      ]
                    ]
        }
    ]
