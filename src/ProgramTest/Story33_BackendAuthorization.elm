module ProgramTest.Story33_BackendAuthorization exposing (endToEndTests)

import Backend
import Dict
import Effect.Test
import HostAdmin
import ProgramTest.Config
import ProgramTest.Actions
import ProgramTest.Query
import ProgramTest.Start
import RemoteData
import Submission
import Types exposing (FrontendMsg(..), ToBackend(..))
import Url exposing (Protocol(..), Url)
import WikiAdminUsers


reviewQueueUrl : Url
reviewQueueUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/Demo/review"
    , query = Nothing
    , fragment = Nothing
    }


expectSubQueueDemoStillPending : Backend.Model -> Result String ()
expectSubQueueDemoStillPending m =
    case Dict.get "sub_1" m.submissions of
        Nothing ->
            Err "expected seeded sub_1"

        Just sub ->
            if sub.status == Submission.Pending then
                Ok ()

            else
                Err "sub_1 should remain Pending when approve is rejected"


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.startWith
        { name = "33 — server-side authz: contributor and host boundaries"
        , config = ProgramTest.Config.demoWikiWithModerationSeeds
        , steps =
            [ ProgramTest.Start.connectFrontend
                { sessionId = "session-story33-contributor-authz"
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
                              , client.update 100 (UrlChanged reviewQueueUrl)
                              , client.checkView 500
                                    (ProgramTest.Query.withinId "wiki-review-queue-error"
                                        (ProgramTest.Query.expectHasText
                                            (Submission.reviewQueueErrorToUserText Submission.ReviewQueueForbidden)
                                        )
                                    )
                              , client.sendToBackend 100 (ApproveSubmission "Demo" "sub_1")
                              , Effect.Test.checkBackend 0 expectSubQueueDemoStillPending
                              , client.sendToBackend 100 (RequestWikiUsers "Demo")
                              , client.checkModel 200
                                    (\model ->
                                        case Dict.get "Demo" model.store.wikiUsers of
                                            Just (RemoteData.Success (Err WikiAdminUsers.Forbidden)) ->
                                                Ok ()

                                            _ ->
                                                Err "expected WikiUsers Forbidden in store after RequestWikiUsers"
                                    )
                              , client.sendToBackend 100 (RequestReviewQueue "ElmTips")
                              , client.checkModel 200
                                    (\model ->
                                        case Dict.get "ElmTips" model.store.reviewQueues of
                                            Just (RemoteData.Success (Err Submission.ReviewQueueWrongWikiSession)) ->
                                                Ok ()

                                            _ ->
                                                Err "expected ReviewQueue WrongWikiSession for elm-tips when session is demo"
                                    )
                              ]
                            ]
                }
            , ProgramTest.Start.connectFrontend
                { sessionId = "session-story33-no-host"
                , path = "/"
                , connectClientMs = Nothing
                , steps =
                    \client ->
                        [ client.sendToBackend 100 RequestHostWikiList
                        , client.checkModel 200
                            (\model ->
                                case model.hostAdminWikis of
                                    RemoteData.Success (Err HostAdmin.NotHostAuthenticated) ->
                                        Ok ()

                                    _ ->
                                        Err "expected host wiki list Err NotHostAuthenticated without host login"
                            )
                        ]
                }
            ]
        }
    ]
