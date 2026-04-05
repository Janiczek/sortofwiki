module ProgramTest.Story19_RequestChanges exposing (endToEndTests)

import Effect.Browser.Dom
import ProgramTest.Actions
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Wiki


guidanceNoteText : String
guidanceNoteText =
    "Add more context and examples before we can approve."


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.startWith
        { name = "19 — trusted requests changes with guidance; author sees Needs revision + note"
        , config = ProgramTest.Config.demoWikiWithModerationSeeds
        , steps =
            [ ProgramTest.Start.connectFrontend
                { sessionId = "session-story19-trusted"
                , path = "/"
                , connectClientMs = Nothing
                , steps =
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
                              , client.clickLink 100 (Wiki.reviewDetailUrlPath "Demo" "sub_2")
                              , client.click 100 (Effect.Browser.Dom.id "wiki-review-decision-request-changes")
                              , client.input 100 (Effect.Browser.Dom.id "wiki-review-request-changes-note") guidanceNoteText
                              , client.click 100 (Effect.Browser.Dom.id "wiki-review-decision-submit")
                              , client.checkView 500
                                    (ProgramTest.Query.withinId "wiki-review-request-changes-success"
                                        (ProgramTest.Query.expectHasText "Revision requested.")
                                    )
                              ]
                            ]
                }
            , ProgramTest.Start.connectFrontend
                { sessionId = "session-story19-contributor"
                , path = "/"
                , connectClientMs = Nothing
                , steps =
                    \client ->
                        List.concat
                            [ ProgramTest.Actions.loginToWiki
                                { wikiSlug = "Demo"
                                , username = "demo_contributor"
                                , password = "password12"
                                }
                                client
                            , [ client.checkView 300
                                    (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                              , client.clickLink 100 (Wiki.mySubmissionsUrlPath "Demo")
                              , client.clickLink 100 (Wiki.submissionDetailUrlPath "Demo" "sub_2")
                              , client.checkView 500
                                    (ProgramTest.Query.withinId "wiki-submission-detail-status"
                                        (ProgramTest.Query.expectHasText "Needs revision")
                                    )
                              , client.checkView 100
                                    (ProgramTest.Query.withinId "wiki-submission-detail-reviewer-note"
                                        (ProgramTest.Query.expectHasText guidanceNoteText)
                                    )
                              ]
                            ]
                }
            ]
        }
    ]
