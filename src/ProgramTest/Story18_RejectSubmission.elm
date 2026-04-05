module ProgramTest.Story18_RejectSubmission exposing (endToEndTests)

import Effect.Browser.Dom
import ProgramTest.Actions
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Wiki


rejectReasonText : String
rejectReasonText =
    "Story 18: harmful or low-quality — blocked by trusted reviewer."


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.startWith
        { name = "18 — trusted rejects pending submission with reason; contributor sees Rejected + note"
        , config = ProgramTest.Config.demoWikiWithModerationSeeds
        , steps =
            [ ProgramTest.Start.connectFrontend
                { sessionId = "session-story18-trusted"
                , path = "/"
                , connectClientMs = Nothing
                , steps =
                    \client ->
                        List.concat
                            [ ProgramTest.Actions.loginToWiki
                                { wikiSlug = "Demo"
                                , username = "trustedpub"
                                , password = "password12"
                                }
                                client
                            , [ client.checkView 300
                                    (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                              , client.clickLink 100 (Wiki.reviewQueueUrlPath "Demo")
                              , client.clickLink 100 (Wiki.reviewDetailUrlPath "Demo" "sub_1")
                              , client.click 100 (Effect.Browser.Dom.id "wiki-review-decision-reject")
                              , client.input 100 (Effect.Browser.Dom.id "wiki-review-reject-reason") rejectReasonText
                              , client.click 100 (Effect.Browser.Dom.id "wiki-review-decision-submit")
                              , client.checkView 500
                                    (ProgramTest.Query.withinId "wiki-review-reject-success"
                                        (ProgramTest.Query.expectHasText "Submission rejected.")
                                    )
                              ]
                            ]
                }
            , ProgramTest.Start.connectFrontend
                { sessionId = "session-story18-contributor"
                , path = "/"
                , connectClientMs = Nothing
                , steps =
                    \client ->
                        List.concat
                            [ ProgramTest.Actions.loginToWiki
                                { wikiSlug = "Demo"
                                , username = "statusdemo"
                                , password = "password12"
                                }
                                client
                            , [ client.checkView 300
                                    (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                              , client.clickLink 100 (Wiki.mySubmissionsUrlPath "Demo")
                              , client.clickLink 100 (Wiki.submissionDetailUrlPath "Demo" "sub_1")
                              , client.checkView 500
                                    (ProgramTest.Query.withinId "wiki-submission-detail-status"
                                        (ProgramTest.Query.expectHasText "Rejected")
                                    )
                              , client.checkView 100
                                    (ProgramTest.Query.withinId "wiki-submission-detail-reviewer-note"
                                        (ProgramTest.Query.expectHasText rejectReasonText)
                                    )
                              ]
                            ]
                }
            ]
        }
    ]
