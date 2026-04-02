module ProgramTest.Story21_PromoteTrusted exposing (endToEndTests)

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
import Wiki


adminUsersUrl : Url
adminUsersUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = Wiki.adminUsersUrlPath "demo"
    , query = Nothing
    , fragment = Nothing
    }


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
        "21 — admin promotes statusdemo to trusted; that user can open review queue"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story21-admin-promote")
            "/w/demo/login"
            { width = 800, height = 600 }
            (\client ->
                [ client.input 100 (Effect.Browser.Dom.id "wiki-login-username") "wikidemo"
                , client.input 100 (Effect.Browser.Dom.id "wiki-login-password") "password12"
                , client.click 100 (Effect.Browser.Dom.id "wiki-login-submit")
                , client.checkView 300
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-login-success" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "You are logged in" ]
                    )
                , client.update 100 (UrlChanged adminUsersUrl)
                , client.checkView 400
                    (\root ->
                        root
                            |> Test.Html.Query.find
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-target-username" "statusdemo")
                                , Test.Html.Selector.class "wiki-admin-promote-trusted"
                                ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Promote" ]
                    )
                , client.click 100
                    (Effect.Browser.Dom.id "wiki-admin-promote-trusted-statusdemo")
                , client.checkView 600
                    (\root ->
                        root
                            |> Test.Html.Query.find
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-admin-user" "statusdemo") ]
                            |> Test.Html.Query.find
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-user-role" "Trusted") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Trusted" ]
                    )
                ]
            )
        , Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story21-promoted-user")
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
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-review-queue-page" ]
                            |> Test.Html.Query.find
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-submission-id" "sub_queue_demo") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "statusdemo" ]
                    )
                ]
            )
        ]
    ]
