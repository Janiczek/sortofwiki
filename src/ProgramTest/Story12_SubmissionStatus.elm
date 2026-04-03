module ProgramTest.Story12_SubmissionStatus exposing (endToEndTests)

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


submitNewUrl : Url
submitNewUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/demo/submit/new"
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


endToEndTests : List (Effect.Test.EndToEndTest ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
endToEndTests =
    [ Effect.Test.start
        "12 — contributor sees Pending on new submission detail"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story12-pending")
            "/w/demo/register"
            { width = 800, height = 600 }
            (\client ->
                [ client.input 100 (Effect.Browser.Dom.id "wiki-register-username") "story12user"
                , client.input 100 (Effect.Browser.Dom.id "wiki-register-password") "password12"
                , client.click 100 (Effect.Browser.Dom.id "wiki-register-submit")
                , client.checkView 300
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-register-success" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Registration complete" ]
                    )
                , client.update 100 (UrlChanged submitNewUrl)
                , client.input 100 (Effect.Browser.Dom.id "wiki-submit-new-slug") "Story12Page"
                , client.input 100 (Effect.Browser.Dom.id "wiki-submit-new-markdown") "# Story 12"
                , client.click 100 (Effect.Browser.Dom.id "wiki-submit-new-submit")
                , client.checkView 300
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-submit-new-success" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "sub_1" ]
                    )
                , client.update 100 (UrlChanged (submissionDetailUrl "sub_1"))
                , client.checkView 400
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-submission-detail-status" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Pending review" ]
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-submission-detail-kind-summary" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "New page: Story12Page" ]
                    )
                ]
            )
        ]
    , Effect.Test.start
        "12 — seeded demo user sees Rejected on sub_rejected_demo (log in as statusdemo / password12)"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story12-seed-rejected")
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
                , client.update 100 (UrlChanged (submissionDetailUrl "sub_rejected_demo"))
                , client.checkView 400
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-submission-detail-status" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Rejected" ]
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-submission-detail-kind-summary" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "New page: seed-rejected" ]
                    )
                ]
            )
        ]
    ]
