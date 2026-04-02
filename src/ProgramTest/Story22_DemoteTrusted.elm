module ProgramTest.Story22_DemoteTrusted exposing (endToEndTests)

import Backend
import Effect.Browser.Dom
import Effect.Lamdera
import Effect.Test
import Effect.Time
import Frontend
import Html.Attributes
import ProgramTest.Config
import Submission
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
        "22 — admin demotes trustedpub; that user cannot open review queue"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story22-admin-demote")
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
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-target-username" "trustedpub")
                                , Test.Html.Selector.class "wiki-admin-demote-trusted"
                                ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Demote" ]
                    )
                , client.click 100
                    (Effect.Browser.Dom.id "wiki-admin-demote-trusted-trustedpub")
                , client.checkView 600
                    (\root ->
                        root
                            |> Test.Html.Query.find
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-admin-user" "trustedpub") ]
                            |> Test.Html.Query.find
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-user-role" "Contributor") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Contributor" ]
                    )
                ]
            )
        , Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story22-demoted-trustedpub")
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
                , client.checkView 500
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-review-queue-error" ]
                            |> Test.Html.Query.has
                                [ Test.Html.Selector.text (Submission.reviewQueueErrorToUserText Submission.ReviewQueueForbidden)
                                ]
                    )
                ]
            )
        ]
    ]
