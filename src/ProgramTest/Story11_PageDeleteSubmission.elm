module ProgramTest.Story11_PageDeleteSubmission exposing (endToEndTests)

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


guidesPageUrl : Url
guidesPageUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/demo/p/guides"
    , query = Nothing
    , fragment = Nothing
    }


submitDeleteGuidesUrl : Url
submitDeleteGuidesUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/demo/submit/delete/guides"
    , query = Nothing
    , fragment = Nothing
    }


demoLoginUrl : Url
demoLoginUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/demo/login"
    , query = Nothing
    , fragment = Nothing
    }


deleteReasonMarker : String
deleteReasonMarker =
    "STORY11_DELETE_REASON"


endToEndTests : List (Effect.Test.EndToEndTest ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
endToEndTests =
    [ Effect.Test.start
        "11 — submit page deletion request; published page unchanged"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story11-delete")
            "/w/demo/register"
            { width = 800, height = 600 }
            (\client ->
                [ client.input 100 (Effect.Browser.Dom.id "wiki-register-username") "story11user"
                , client.input 100 (Effect.Browser.Dom.id "wiki-register-password") "password12"
                , client.click 100 (Effect.Browser.Dom.id "wiki-register-submit")
                , client.checkView 300
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-register-success" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Registration complete" ]
                    )
                , client.update 100 (UrlChanged demoLoginUrl)
                , client.input 100 (Effect.Browser.Dom.id "wiki-login-username") "story11user"
                , client.input 100 (Effect.Browser.Dom.id "wiki-login-password") "password12"
                , client.click 100 (Effect.Browser.Dom.id "wiki-login-submit")
                , client.checkView 300
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-login-success" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "You are logged in" ]
                    )
                , client.update 100 (UrlChanged guidesPageUrl)
                , client.checkView 200
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-page-request-deletion" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Request deletion" ]
                    )
                , client.update 100 (UrlChanged submitDeleteGuidesUrl)
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-submit-delete-page" ]
                            |> Test.Html.Query.has
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-wiki-slug" "demo")
                                , Test.Html.Selector.attribute (Html.Attributes.attribute "data-page-slug" "guides")
                                ]
                    )
                , client.input 100 (Effect.Browser.Dom.id "wiki-submit-delete-reason") deleteReasonMarker
                , client.click 100 (Effect.Browser.Dom.id "wiki-submit-delete-submit")
                , client.checkView 300
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-submit-delete-success" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "sub_1" ]
                    )
                , client.update 100 (UrlChanged guidesPageUrl)
                , client.checkView 200
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "page-markdown" ]
                            |> Test.Html.Query.find [ Test.Html.Selector.tag "h2" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "How to use this wiki" ]
                    )
                ]
            )
        ]
    ]
