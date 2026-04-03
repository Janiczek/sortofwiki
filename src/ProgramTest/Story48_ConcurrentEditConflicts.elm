module ProgramTest.Story48_ConcurrentEditConflicts exposing (endToEndTests)

import Backend
import Effect.Browser.Dom
import Effect.Lamdera
import Effect.Test
import Effect.Time
import Frontend
import ProgramTest.Config
import Submission
import Test.Html.Query
import Test.Html.Selector
import Types exposing (FrontendMsg(..), ToBackend, ToFrontend)
import Url exposing (Protocol(..), Url)


submitEditGuidesUrl : Url
submitEditGuidesUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/demo/submit/edit/Guides"
    , query = Nothing
    , fragment = Nothing
    }


reviewSub1Url : Url
reviewSub1Url =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/demo/review/sub_1"
    , query = Nothing
    , fragment = Nothing
    }


submission2Url : Url
submission2Url =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/demo/submit/sub_2"
    , query = Nothing
    , fragment = Nothing
    }


editA : String
editA =
    "# Story48 edit A"


editB : String
editB =
    "# Story48 edit B"


editBResolved : String
editBResolved =
    "# Story48 resolved edit B"


endToEndTests : List (Effect.Test.EndToEndTest ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
endToEndTests =
    [ Effect.Test.start
        "48 — concurrent pending edits roll stale ones to needs-revision and support resubmit"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story48-user-a")
            "/w/demo/register"
            { width = 800, height = 600 }
            (\client ->
                [ client.input 100 (Effect.Browser.Dom.id "wiki-register-username") "story48a"
                , client.input 100 (Effect.Browser.Dom.id "wiki-register-password") "password12"
                , client.click 100 (Effect.Browser.Dom.id "wiki-register-submit")
                , client.update 100 (UrlChanged submitEditGuidesUrl)
                , client.input 100 (Effect.Browser.Dom.id "wiki-submit-edit-markdown") editA
                , client.click 100 (Effect.Browser.Dom.id "wiki-submit-edit-submit")
                , client.checkView 300
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-submit-edit-success" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "sub_1" ]
                    )
                ]
            )
        , Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story48-user-b")
            "/w/demo/register"
            { width = 800, height = 600 }
            (\client ->
                [ client.input 100 (Effect.Browser.Dom.id "wiki-register-username") "story48b"
                , client.input 100 (Effect.Browser.Dom.id "wiki-register-password") "password12"
                , client.click 100 (Effect.Browser.Dom.id "wiki-register-submit")
                , client.update 100 (UrlChanged submitEditGuidesUrl)
                , client.input 100 (Effect.Browser.Dom.id "wiki-submit-edit-markdown") editB
                , client.click 100 (Effect.Browser.Dom.id "wiki-submit-edit-submit")
                , client.checkView 300
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-submit-edit-success" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "sub_2" ]
                    )
                , client.update 100 (UrlChanged submitEditGuidesUrl)
                , client.input 100 (Effect.Browser.Dom.id "wiki-submit-edit-markdown") "# duplicate pending attempt"
                , client.click 100 (Effect.Browser.Dom.id "wiki-submit-edit-submit")
                , client.checkView 300
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-submit-edit-error-text" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "already have a pending edit for this page" ]
                    )
                ]
            )
        , Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story48-trusted")
            "/w/demo/login"
            { width = 800, height = 600 }
            (\client ->
                [ client.input 100 (Effect.Browser.Dom.id "wiki-login-username") "trustedpub"
                , client.input 100 (Effect.Browser.Dom.id "wiki-login-password") "password12"
                , client.click 100 (Effect.Browser.Dom.id "wiki-login-submit")
                , client.update 100 (UrlChanged reviewSub1Url)
                , client.click 100 (Effect.Browser.Dom.id "wiki-review-approve-submit")
                , client.checkView 400
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-review-approve-success" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Submission approved and published." ]
                    )
                ]
            )
        , Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story48-user-b")
            "/w/demo/login"
            { width = 800, height = 600 }
            (\client ->
                [ client.input 100 (Effect.Browser.Dom.id "wiki-login-username") "story48b"
                , client.input 100 (Effect.Browser.Dom.id "wiki-login-password") "password12"
                , client.click 100 (Effect.Browser.Dom.id "wiki-login-submit")
                , client.update 100 (UrlChanged submission2Url)
                , client.checkView 500
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-submission-detail-status" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Needs revision" ]
                    )
                , client.checkView 200
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-submission-detail-reviewer-note" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Page changed after this edit was submitted" ]
                    )
                , client.checkView 200
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-submission-detail-base-markdown" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "How to use this wiki" ]
                    )
                , client.checkView 200
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-submission-detail-current-markdown" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text editA ]
                    )
                , client.input 100 (Effect.Browser.Dom.id "wiki-submission-detail-resubmit-markdown") "   "
                , client.click 100 (Effect.Browser.Dom.id "wiki-submission-detail-resubmit-submit")
                , client.checkView 200
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-submission-detail-resubmit-error" ]
                            |> Test.Html.Query.has
                                [ Test.Html.Selector.text
                                    (Submission.resubmitPageEditErrorToUserText
                                        (Submission.ResubmitEditValidation Submission.BodyEmpty)
                                    )
                                ]
                    )
                , client.input 100 (Effect.Browser.Dom.id "wiki-submission-detail-resubmit-markdown") editBResolved
                , client.click 100 (Effect.Browser.Dom.id "wiki-submission-detail-resubmit-submit")
                , client.checkView 400
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-submission-detail-status" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Pending review" ]
                    )
                ]
            )
        ]
    ]
