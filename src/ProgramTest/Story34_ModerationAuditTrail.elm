module ProgramTest.Story34_ModerationAuditTrail exposing (endToEndTests)

import Effect.Browser.Dom
import ProgramTest.Config
import ProgramTest.LoginSteps
import ProgramTest.Query
import ProgramTest.Start
import Wiki


rejectReasonStory34 : String
rejectReasonStory34 =
    "Story 34: reject path must appear in wiki admin audit."


requestChangesNoteStory34 : String
requestChangesNoteStory34 =
    "Story 34: request-changes path must appear in wiki admin audit."


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.startWith
        { name = "34 — trusted approves; wiki admin audit row shows time label and moderator actor"
        , config = ProgramTest.Config.demoWikiWithModerationSeeds
        , steps =
            [ ProgramTest.Start.connectFrontend
                { sessionId = "session-story34-approve-trusted"
                , path = "/"
                , connectClientMs = Nothing
                , steps =
                    \client ->
                        List.concat
                            [ ProgramTest.LoginSteps.loginToWiki
                                { wikiSlug = "Demo"
                                , username = "trustedpub"
                                , password = "password12"
                                }
                                client
                            , [ client.checkView 300
                                    (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                              , client.clickLink 100 (Wiki.reviewQueueUrlPath "Demo")
                              , client.clickLink 100 (Wiki.reviewDetailUrlPath "Demo" "sub_1")
                              , client.click 100 (Effect.Browser.Dom.id "wiki-review-decision-submit")
                              , client.checkView 500
                                    (ProgramTest.Query.withinId "wiki-review-approve-success"
                                        (ProgramTest.Query.expectHasText "Submission approved and published.")
                                    )
                              ]
                            ]
                }
            , ProgramTest.Start.connectFrontend
                { sessionId = "session-story34-approve-admin"
                , path = "/"
                , connectClientMs = Nothing
                , steps =
                    \client ->
                        List.concat
                            [ ProgramTest.LoginSteps.loginToWiki
                                { wikiSlug = "Demo"
                                , username = "wikidemo"
                                , password = "password12"
                                }
                                client
                            , [ client.checkView 300
                                    (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                              , client.clickLink 100 (Wiki.adminAuditUrlPath "Demo")
                              , client.checkView 600
                                    (ProgramTest.Query.withinId "wiki-admin-audit-list"
                                        (ProgramTest.Query.expectHasTexts
                                            [ "trustedpub"
                                            , "Approved submission"
                                            ]
                                        )
                                    )
                              ]
                            ]
                }
            ]
        }
    , ProgramTest.Start.startWith
        { name = "34 — trusted rejects; wiki admin audit shows rejected submission and actor"
        , config = ProgramTest.Config.demoWikiWithModerationSeeds
        , steps =
            [ ProgramTest.Start.connectFrontend
                { sessionId = "session-story34-reject-trusted"
                , path = "/"
                , connectClientMs = Nothing
                , steps =
                    \client ->
                        List.concat
                            [ ProgramTest.LoginSteps.loginToWiki
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
                              , client.input 100 (Effect.Browser.Dom.id "wiki-review-reject-reason") rejectReasonStory34
                              , client.click 100 (Effect.Browser.Dom.id "wiki-review-decision-submit")
                              , client.checkView 500
                                    (ProgramTest.Query.withinId "wiki-review-reject-success"
                                        (ProgramTest.Query.expectHasText "Submission rejected.")
                                    )
                              ]
                            ]
                }
            , ProgramTest.Start.connectFrontend
                { sessionId = "session-story34-reject-admin"
                , path = "/"
                , connectClientMs = Nothing
                , steps =
                    \client ->
                        List.concat
                            [ ProgramTest.LoginSteps.loginToWiki
                                { wikiSlug = "Demo"
                                , username = "wikidemo"
                                , password = "password12"
                                }
                                client
                            , [ client.checkView 300
                                    (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                              , client.clickLink 100 (Wiki.adminAuditUrlPath "Demo")
                              , client.checkView 600
                                    (ProgramTest.Query.withinId "wiki-admin-audit-list"
                                        (ProgramTest.Query.expectHasTexts
                                            [ "trustedpub"
                                            , "Rejected submission"
                                            ]
                                        )
                                    )
                              ]
                            ]
                }
            ]
        }
    , ProgramTest.Start.startWith
        { name = "34 — trusted requests changes; wiki admin audit shows request and actor"
        , config = ProgramTest.Config.demoWikiWithModerationSeeds
        , steps =
            [ ProgramTest.Start.connectFrontend
                { sessionId = "session-story34-changes-trusted"
                , path = "/"
                , connectClientMs = Nothing
                , steps =
                    \client ->
                        List.concat
                            [ ProgramTest.LoginSteps.loginToWiki
                                { wikiSlug = "Demo"
                                , username = "trustedpub"
                                , password = "password12"
                                }
                                client
                            , [ client.checkView 300
                                    (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                              , client.clickLink 100 (Wiki.reviewQueueUrlPath "Demo")
                              , client.clickLink 100 (Wiki.reviewDetailUrlPath "Demo" "sub_2")
                              , client.click 100 (Effect.Browser.Dom.id "wiki-review-decision-request-changes")
                              , client.input 100 (Effect.Browser.Dom.id "wiki-review-request-changes-note") requestChangesNoteStory34
                              , client.click 100 (Effect.Browser.Dom.id "wiki-review-decision-submit")
                              , client.checkView 500
                                    (ProgramTest.Query.withinId "wiki-review-request-changes-success"
                                        (ProgramTest.Query.expectHasText "Revision requested.")
                                    )
                              ]
                            ]
                }
            , ProgramTest.Start.connectFrontend
                { sessionId = "session-story34-changes-admin"
                , path = "/"
                , connectClientMs = Nothing
                , steps =
                    \client ->
                        List.concat
                            [ ProgramTest.LoginSteps.loginToWiki
                                { wikiSlug = "Demo"
                                , username = "wikidemo"
                                , password = "password12"
                                }
                                client
                            , [ client.checkView 300
                                    (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                              , client.clickLink 100 (Wiki.adminAuditUrlPath "Demo")
                              , client.checkView 600
                                    (ProgramTest.Query.withinId "wiki-admin-audit-list"
                                        (ProgramTest.Query.expectHasTexts
                                            [ "trustedpub"
                                            , "Requested changes"
                                            ]
                                        )
                                    )
                              ]
                            ]
                }
            ]
        }
    ]
