module ProgramTest.Story33_BackendAuthorization exposing (endToEndTests)

import Backend
import Dict
import Effect.Browser.Dom
import Effect.Lamdera
import Effect.Test
import Effect.Time
import Frontend
import HostAdmin
import ProgramTest.Config
import RemoteData
import Submission
import Test.Html.Query
import Test.Html.Selector
import Types exposing (FrontendMsg(..), ToBackend(..), ToFrontend)
import Url exposing (Protocol(..), Url)
import WikiAdminUsers


reviewQueueUrl : Url
reviewQueueUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/demo/review"
    , query = Nothing
    , fragment = Nothing
    }


homeUrl : Url
homeUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/"
    , query = Nothing
    , fragment = Nothing
    }


expectSubQueueDemoStillPending : Backend.Model -> Result String ()
expectSubQueueDemoStillPending m =
    case Dict.get "sub_queue_demo" m.submissions of
        Nothing ->
            Err "expected seeded sub_queue_demo"

        Just sub ->
            if sub.status == Submission.Pending then
                Ok ()

            else
                Err "sub_queue_demo should remain Pending when approve is rejected"


endToEndTests : List (Effect.Test.EndToEndTest ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
endToEndTests =
    [ Effect.Test.start
        "33 — server-side authz: contributor and host boundaries"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story33-contributor-authz")
            "/w/demo/login"
            { width = 800, height = 600 }
            (\client ->
                [ client.input 100 (Effect.Browser.Dom.id "wiki-login-username") "statusdemo"
                , client.input 100 (Effect.Browser.Dom.id "wiki-login-password") "password12"
                , client.click 100 (Effect.Browser.Dom.id "wiki-login-submit")
                , client.checkView 300
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-login-success" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "You are logged in" ]
                    )
                , client.update 100 (UrlChanged reviewQueueUrl)
                , client.checkView 500
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-review-queue-error" ]
                            |> Test.Html.Query.has
                                [ Test.Html.Selector.text (Submission.reviewQueueErrorToUserText Submission.ReviewQueueForbidden)
                                ]
                    )
                , client.sendToBackend 100 (ApproveSubmission "demo" "sub_queue_demo")
                , Effect.Test.checkBackend 0 expectSubQueueDemoStillPending
                , client.sendToBackend 100 (RequestWikiUsers "demo")
                , client.checkModel 200
                    (\model ->
                        case Dict.get "demo" model.store.wikiUsers of
                            Just (RemoteData.Success (Err WikiAdminUsers.Forbidden)) ->
                                Ok ()

                            _ ->
                                Err "expected WikiUsers Forbidden in store after RequestWikiUsers"
                    )
                , client.sendToBackend 100 (RequestReviewQueue "elm-tips")
                , client.checkModel 200
                    (\model ->
                        case Dict.get "elm-tips" model.store.reviewQueues of
                            Just (RemoteData.Success (Err Submission.ReviewQueueWrongWikiSession)) ->
                                Ok ()

                            _ ->
                                Err "expected ReviewQueue WrongWikiSession for elm-tips when session is demo"
                    )
                ]
            )
        , Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story33-no-host")
            "/"
            { width = 800, height = 600 }
            (\client ->
                [ client.update 100 (UrlChanged homeUrl)
                , client.sendToBackend 100 RequestHostWikiList
                , client.checkModel 200
                    (\model ->
                        case model.hostAdminWikis of
                            RemoteData.Success (Err HostAdmin.NotHostAuthenticated) ->
                                Ok ()

                            _ ->
                                Err "expected host wiki list Err NotHostAuthenticated without host login"
                    )
                ]
            )
        ]
    ]
