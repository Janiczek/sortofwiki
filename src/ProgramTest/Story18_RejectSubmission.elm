module ProgramTest.Story18_RejectSubmission exposing (endToEndTests)

import Backend
import Effect.Browser.Dom
import Effect.Lamdera
import Effect.Test
import Effect.Time
import Frontend
import ProgramTest.Config
import Test.Html.Query
import Test.Html.Selector
import Types exposing (FrontendMsg(..), ToBackend, ToFrontend)
import Url exposing (Protocol(..), Url)


reviewQueueDemoUrl : Url
reviewQueueDemoUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/demo/review/sub_queue_demo"
    , query = Nothing
    , fragment = Nothing
    }


submissionDetailUrl : String -> Url
submissionDetailUrl submissionId =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/demo/submit/" ++ submissionId
    , query = Nothing
    , fragment = Nothing
    }


rejectReasonText : String
rejectReasonText =
    "Story 18: harmful or low-quality — blocked by trusted reviewer."


endToEndTests : List (Effect.Test.EndToEndTest ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
endToEndTests =
    [ Effect.Test.start
        "18 — trusted rejects pending submission with reason; contributor sees Rejected + note"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story18-trusted")
            "/w/demo/login"
            { width = 800, height = 600 }
            (\client ->
                [ client.input 100 (Effect.Browser.Dom.id "wiki-login-username") "trustedpub"
                , client.input 100 (Effect.Browser.Dom.id "wiki-login-password") "password12"
                , client.click 100 (Effect.Browser.Dom.id "wiki-login-submit")
                , client.checkView 300
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-login-success" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "You are logged in" ]
                    )
                , client.update 100 (UrlChanged reviewQueueDemoUrl)
                , client.input 100 (Effect.Browser.Dom.id "wiki-review-reject-reason") rejectReasonText
                , client.click 100 (Effect.Browser.Dom.id "wiki-review-reject-submit")
                , client.checkView 500
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-review-reject-success" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Submission rejected." ]
                    )
                ]
            )
        , Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story18-contributor")
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
                , client.update 100 (UrlChanged (submissionDetailUrl "sub_queue_demo"))
                , client.checkView 500
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-submission-detail-status" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Rejected" ]
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-submission-detail-reviewer-note" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text rejectReasonText ]
                    )
                ]
            )
        ]
    ]
