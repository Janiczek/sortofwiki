module ProgramTest.Story10_PageEditSubmission exposing (endToEndTests)

import Backend
import Effect.Browser.Dom
import Effect.Lamdera
import Effect.Test
import Effect.Time
import Expect
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


submitEditGuidesUrl : Url
submitEditGuidesUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/demo/submit/edit/guides"
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


proposedEditMarker : String
proposedEditMarker =
    "STORY10_PROPOSED_EDIT_BODY"


endToEndTests : List (Effect.Test.EndToEndTest ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
endToEndTests =
    [ Effect.Test.start
        "10 — submit page edit proposal; published content unchanged"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story10-edit")
            "/w/demo/register"
            { width = 800, height = 600 }
            (\client ->
                [ client.input 100 (Effect.Browser.Dom.id "wiki-register-username") "story10user"
                , client.input 100 (Effect.Browser.Dom.id "wiki-register-password") "password12"
                , client.click 100 (Effect.Browser.Dom.id "wiki-register-submit")
                , client.checkView 300
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-register-success" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Registration complete" ]
                    )
                , client.update 100 (UrlChanged demoLoginUrl)
                , client.input 100 (Effect.Browser.Dom.id "wiki-login-username") "story10user"
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
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-page-propose-edit" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Propose edit" ]
                    )
                , client.update 100 (UrlChanged submitEditGuidesUrl)
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-submit-edit-page" ]
                            |> Test.Html.Query.has
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-wiki-slug" "demo")
                                , Test.Html.Selector.attribute (Html.Attributes.attribute "data-page-slug" "guides")
                                ]
                    )
                , client.input 100 (Effect.Browser.Dom.id "wiki-submit-edit-markdown") ("# " ++ proposedEditMarker)
                , client.click 100 (Effect.Browser.Dom.id "wiki-submit-edit-submit")
                , client.checkView 300
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-submit-edit-success" ]
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
                , client.checkView 200
                    (\root ->
                        root
                            |> Test.Html.Query.findAll [ Test.Html.Selector.text proposedEditMarker ]
                            |> Test.Html.Query.count (Expect.equal 0)
                    )
                ]
            )
        ]
    ]
