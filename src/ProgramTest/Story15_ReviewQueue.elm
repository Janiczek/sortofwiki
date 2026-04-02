module ProgramTest.Story15_ReviewQueue exposing (endToEndTests)

import Backend
import Effect.Browser.Dom
import Effect.Lamdera
import Effect.Test
import Effect.Time
import Frontend
import Html.Attributes
import ProgramTest.Config
import Test.Html.Query
import Test.Html.Selector
import Types exposing (FrontendMsg(..), ToBackend, ToFrontend)
import Url exposing (Protocol(..), Url)


reviewQueueUrl : Url
reviewQueueUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/demo/review"
    , query = Nothing
    , fragment = Nothing
    }


endToEndTests : List (Effect.Test.EndToEndTest ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
endToEndTests =
    [ Effect.Test.start
        "15 — trusted contributor sees standard user's pending submission in review queue"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story15-review-queue")
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
                , client.update 100 (UrlChanged reviewQueueUrl)
                , client.checkView 400
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-review-queue-page" ]
                            |> Test.Html.Query.find
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-submission-id" "sub_queue_demo") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "statusdemo" ]
                    )
                ]
            )
        ]
    ]
