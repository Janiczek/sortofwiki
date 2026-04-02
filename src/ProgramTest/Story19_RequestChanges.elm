module ProgramTest.Story19_RequestChanges exposing (endToEndTests)

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


reviewChangesDemoUrl : Url
reviewChangesDemoUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/demo/review/sub_changes_demo"
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


guidanceNoteText : String
guidanceNoteText =
    "Story 19: add more context and examples before we can approve."


endToEndTests : List (Effect.Test.EndToEndTest ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
endToEndTests =
    [ Effect.Test.start
        "19 — trusted requests changes with guidance; author sees Needs revision + note"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story19-trusted")
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
                , client.update 100 (UrlChanged reviewChangesDemoUrl)
                , client.input 100 (Effect.Browser.Dom.id "wiki-review-request-changes-note") guidanceNoteText
                , client.click 100 (Effect.Browser.Dom.id "wiki-review-request-changes-submit")
                , client.checkView 500
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-review-request-changes-success" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Revision requested." ]
                    )
                ]
            )
        , Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story19-contributor")
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
                , client.update 100 (UrlChanged (submissionDetailUrl "sub_changes_demo"))
                , client.checkView 500
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-submission-detail-status" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Needs revision" ]
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-submission-detail-reviewer-note" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text guidanceNoteText ]
                    )
                ]
            )
        ]
    ]
