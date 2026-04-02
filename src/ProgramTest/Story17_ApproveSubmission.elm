module ProgramTest.Story17_ApproveSubmission exposing (endToEndTests)

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


queueDemoPublishedPageUrl : Url
queueDemoPublishedPageUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/demo/p/queue-demo-page"
    , query = Nothing
    , fragment = Nothing
    }


endToEndTests : List (Effect.Test.EndToEndTest ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
endToEndTests =
    [ Effect.Test.start
        "17 — trusted contributor approves pending new-page submission; page goes live"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story17-approve")
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
                , client.checkView 400
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-review-approve-submit" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Approve" ]
                    )
                , client.click 100 (Effect.Browser.Dom.id "wiki-review-approve-submit")
                , client.checkView 500
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-review-approve-success" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Submission approved and published." ]
                    )
                , client.update 100 (UrlChanged queueDemoPublishedPageUrl)
                , client.checkView 400
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "page-markdown" ]
                            |> Test.Html.Query.has
                                [ Test.Html.Selector.text "Seeded pending submission for the trusted review queue (story 15)." ]
                    )
                ]
            )
        ]
    ]
