module ProgramTest.Story34_ModerationAuditTrail exposing (endToEndTests)

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


adminAuditUrl : Url
adminAuditUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = Wiki.adminAuditUrlPath "demo"
    , query = Nothing
    , fragment = Nothing
    }


reviewQueueDemoUrl : Url
reviewQueueDemoUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/demo/review/sub_queue_demo"
    , query = Nothing
    , fragment = Nothing
    }


reviewChangesDemoUrl : Url
reviewChangesDemoUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/demo/review/sub_changes_demo"
    , query = Nothing
    , fragment = Nothing
    }


rejectReasonStory34 : String
rejectReasonStory34 =
    "Story 34: reject path must appear in wiki admin audit."


requestChangesNoteStory34 : String
requestChangesNoteStory34 =
    "Story 34: request-changes path must appear in wiki admin audit."


endToEndTests : List (Effect.Test.EndToEndTest ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
endToEndTests =
    [ Effect.Test.start
        "34 — trusted approves; wiki admin audit row shows time label and moderator actor"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story34-approve-trusted")
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
                , client.click 100 (Effect.Browser.Dom.id "wiki-review-approve-submit")
                , client.checkView 500
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-review-approve-success" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Submission approved and published." ]
                    )
                ]
            )
        , Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story34-approve-admin")
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
                , client.update 100 (UrlChanged adminAuditUrl)
                , client.checkView 600
                    (\root ->
                        root
                            |> Test.Html.Query.find
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-audit-event" "0") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "t=" ]
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-audit-event" "0") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "trustedpub" ]
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-audit-event" "0") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Approved submission" ]
                    )
                ]
            )
        ]
    , Effect.Test.start
        "34 — trusted rejects; wiki admin audit shows rejected submission and actor"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story34-reject-trusted")
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
                , client.input 100 (Effect.Browser.Dom.id "wiki-review-reject-reason") rejectReasonStory34
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
            (Effect.Lamdera.sessionIdFromString "session-story34-reject-admin")
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
                , client.update 100 (UrlChanged adminAuditUrl)
                , client.checkView 600
                    (\root ->
                        root
                            |> Test.Html.Query.find
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-audit-event" "0") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "t=" ]
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-audit-event" "0") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "trustedpub" ]
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-audit-event" "0") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Rejected submission" ]
                    )
                ]
            )
        ]
    , Effect.Test.start
        "34 — trusted requests changes; wiki admin audit shows request and actor"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story34-changes-trusted")
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
                , client.input 100 (Effect.Browser.Dom.id "wiki-review-request-changes-note") requestChangesNoteStory34
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
            (Effect.Lamdera.sessionIdFromString "session-story34-changes-admin")
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
                , client.update 100 (UrlChanged adminAuditUrl)
                , client.checkView 600
                    (\root ->
                        root
                            |> Test.Html.Query.find
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-audit-event" "0") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "t=" ]
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-audit-event" "0") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "trustedpub" ]
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-audit-event" "0") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Requested changes" ]
                    )
                ]
            )
        ]
    ]
