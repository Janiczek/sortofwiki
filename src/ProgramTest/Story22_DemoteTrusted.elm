module ProgramTest.Story22_DemoteTrusted exposing (endToEndTests)

import Effect.Browser.Dom
import ProgramTest.Actions
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Submission
import Types exposing (FrontendMsg(..))
import Url exposing (Protocol(..), Url)
import Wiki


reviewQueueUrl : Url
reviewQueueUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/Demo/review"
    , query = Nothing
    , fragment = Nothing
    }


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.startWith
        { name = "22 — admin demotes demo_trusted_publisher; that user cannot open review queue"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , steps =
            [ ProgramTest.Start.connectFrontend
                { sessionId = "session-story22-admin-demote"
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
                                        [ ( "data-target-username", "demo_trusted_publisher" )
                                        , ( "data-context", "wiki-admin-demote-trusted" )
                                        ]
                                        (ProgramTest.Query.expectHasText "Demote")
                                    )
                              , client.click 100
                                    (Effect.Browser.Dom.id "wiki-admin-demote-trusted-demo_trusted_publisher")
                              , client.checkView 600
                                    (ProgramTest.Query.withinDataAttribute "data-admin-user"
                                        "demo_trusted_publisher"
                                        (ProgramTest.Query.withinDataAttribute "data-user-role"
                                            "Contributor"
                                            (ProgramTest.Query.expectHasText "Contributor")
                                        )
                                    )
                              ]
                            ]
                }
            , ProgramTest.Start.connectFrontend
                { sessionId = "session-story22-demoted-demo_trusted_publisher"
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
                              , client.update 100 (UrlChanged reviewQueueUrl)
                              , client.checkView 500
                                    (ProgramTest.Query.withinId "wiki-review-queue-error"
                                        (ProgramTest.Query.expectHasText (Submission.reviewQueueErrorToUserText Submission.ReviewQueueForbidden))
                                    )
                              ]
                            ]
                }
            ]
        }
    ]
