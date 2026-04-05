module ProgramTest.Story21_PromoteTrusted exposing (endToEndTests)

import Effect.Browser.Dom
import ProgramTest.Actions
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Wiki


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.startWith
        { name = "21 — admin promotes demo_contributor to trusted; that user can open review queue"
        , config = ProgramTest.Config.demoWikiWithModerationSeeds
        , steps =
            [ ProgramTest.Start.connectFrontend
                { sessionId = "session-story21-admin-promote"
                , path = "/"
                , connectClientMs = Nothing
                , steps =
                    \client ->
                        List.concat
                            [ ProgramTest.Actions.loginToWiki
                                { wikiSlug = "Demo"
                                , username = "demo_wiki_admin"
                                , password = "password12"
                                }
                                client
                            , [ client.checkView 300
                                    (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                              , client.clickLink 100 (Wiki.adminUsersUrlPath "Demo")
                              , client.checkView 400
                                    (ProgramTest.Query.withinDataAttributes
                                        [ ( "data-target-username", "demo_contributor" )
                                        , ( "data-context", "wiki-admin-promote-trusted" )
                                        ]
                                        (ProgramTest.Query.expectHasText "Promote")
                                    )
                              , client.click 100
                                    (Effect.Browser.Dom.id "wiki-admin-promote-trusted-demo_contributor")
                              , client.checkView 600
                                    (ProgramTest.Query.withinDataAttribute "data-admin-user"
                                        "demo_contributor"
                                        (ProgramTest.Query.withinDataAttribute "data-user-role"
                                            "Trusted"
                                            (ProgramTest.Query.expectHasText "Trusted")
                                        )
                                    )
                              ]
                            ]
                }
            , ProgramTest.Start.connectFrontend
                { sessionId = "session-story21-promoted-user"
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
                              , client.clickLink 100 (Wiki.reviewQueueUrlPath "Demo")
                              , client.checkView 500
                                    (ProgramTest.Query.withinId "wiki-review-queue-page"
                                        (ProgramTest.Query.withinDataAttribute "data-submission-id"
                                            "sub_1"
                                            (ProgramTest.Query.expectHasText "demo_contributor")
                                        )
                                    )
                              ]
                            ]
                }
            ]
        }
    ]
