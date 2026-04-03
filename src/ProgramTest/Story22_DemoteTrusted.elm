module ProgramTest.Story22_DemoteTrusted exposing (endToEndTests)

import Effect.Browser.Dom
import ProgramTest.Config
import ProgramTest.LoginSteps
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
        { name = "22 — admin demotes trustedpub; that user cannot open review queue"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , steps =
            [ ProgramTest.Start.connectFrontend
                { sessionId = "session-story22-admin-demote"
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
                              , client.clickLink 100 (Wiki.adminUsersUrlPath "Demo")
                              , client.checkView 400
                                    (ProgramTest.Query.withinDataAttributes
                                        [ ( "data-target-username", "trustedpub" )
                                        , ( "data-context", "wiki-admin-demote-trusted" )
                                        ]
                                        (ProgramTest.Query.expectHasText "Demote")
                                    )
                              , client.click 100
                                    (Effect.Browser.Dom.id "wiki-admin-demote-trusted-trustedpub")
                              , client.checkView 600
                                    (ProgramTest.Query.withinDataAttribute "data-admin-user" "trustedpub"
                                        (ProgramTest.Query.withinDataAttribute "data-user-role" "Contributor"
                                            (ProgramTest.Query.expectHasText "Contributor")
                                        )
                                    )
                              ]
                            ]
                }
            , ProgramTest.Start.connectFrontend
                { sessionId = "session-story22-demoted-trustedpub"
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
