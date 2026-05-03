module ProgramTest.Story09_NewPageSubmission exposing (endToEndTests)

import Effect.Browser.Dom
import Expect
import ProgramTest.Actions
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Types exposing (FrontendMsg(..))
import Url exposing (Protocol(..), Url)
import Wiki


pendingPageUrl : Url
pendingPageUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/Demo/p/Story09NewPage"
    , query = Nothing
    , fragment = Nothing
    }


submitNewPageUrl : Url
submitNewPageUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/Demo/submit/new"
    , query = Just "page=Story09NewPage"
    , fragment = Nothing
    }


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    List.concat
        [ ProgramTest.Start.bothViewports
            { baseName = "9 — save new-page draft off index; submit for review; missing-page copy"
            , config = ProgramTest.Config.demoWikiPagesOnly
            , sessionId = "session-story09-submit"
            , path = "/w/Demo/register"
            , connectClientMs = Nothing
            , clientSteps =
                \client ->
                    List.concat
                        [ [ client.input 100 (Effect.Browser.Dom.id "wiki-register-username") "story09user"
                          , client.input 100 (Effect.Browser.Dom.id "wiki-register-password") "password12"
                          ]
                        , ProgramTest.Actions.triggerFormSubmit "wiki-register-form" client
                        , [ client.checkView 400
                                (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                          , client.update 100 (UrlChanged submitNewPageUrl)
                          , client.checkView 100
                                (ProgramTest.Query.withinId "wiki-submit-new-page"
                                    (ProgramTest.Query.expectHasDataAttributes
                                        [ ( "data-wiki-slug", "Demo" )
                                        , ( "data-page-slug", "Story09NewPage" )
                                        ]
                                    )
                                )
                          , client.checkView 100
                                (ProgramTest.Query.withinId "wiki-submit-new-submit"
                                    (ProgramTest.Query.expectHasText "Submit for review")
                                )
                          , client.input 100 (Effect.Browser.Dom.id "content-markdown-textarea") "# Story 09 page"
                          , client.click 100 (Effect.Browser.Dom.id "wiki-submit-new-save-draft")
                          , client.checkView 400
                                (ProgramTest.Query.withinId "wiki-submit-new-save-draft-success"
                                    (ProgramTest.Query.expectHasText "Draft saved.")
                                )
                          ]
                        , ProgramTest.Actions.navigateToWikiHome "Demo" client
                        , [ client.checkView 200
                                (ProgramTest.Query.withinId "wiki-home-page-slugs"
                                    (ProgramTest.Query.expectDataAttributeOccurrenceCount "data-page-slug" "Story09NewPage" (\c -> c |> Expect.equal 0))
                                )
                          , client.update 100 (UrlChanged pendingPageUrl)
                          , client.checkView 500
                                (ProgramTest.Query.expectAll
                                    [ ProgramTest.Query.expectHasNotId "page-published-page"
                                    , ProgramTest.Query.withinId "wiki-missing-published-page"
                                        (ProgramTest.Query.expectAll
                                            [ ProgramTest.Query.expectHasText "does not exist yet"
                                            , ProgramTest.Query.expectHasText "saved draft"
                                            ]
                                        )
                                    , ProgramTest.Query.withinId "wiki-missing-published-pending-notice"
                                        (ProgramTest.Query.expectAll
                                            [ ProgramTest.Query.expectHasDataAttributes
                                                [ ( "data-pending-submission-id", "sub_1" )
                                                , ( "data-missing-page-submission-status", "Draft" )
                                                ]
                                            ]
                                        )
                                    , ProgramTest.Query.withinLayoutHeader
                                        (ProgramTest.Query.expectAll
                                            [ ProgramTest.Query.expectHasText ": Create?"
                                            , ProgramTest.Query.expectHasText "Story09NewPage"
                                            ]
                                        )
                                    ]
                                )
                          , client.clickLink 100 (Wiki.submissionDetailUrlPath "Demo" "sub_1")
                          , client.checkView 400
                                (ProgramTest.Query.withinId "wiki-submission-detail-status"
                                    (ProgramTest.Query.expectHasText "Draft")
                                )
                          , client.click 100 (Effect.Browser.Dom.id "wiki-submission-detail-submit-for-review")
                          , client.checkView 500
                                (ProgramTest.Query.withinId "wiki-submission-detail-status"
                                    (ProgramTest.Query.expectHasText "Pending review")
                                )
                          , client.update 100 (UrlChanged pendingPageUrl)
                          , client.checkView 400
                                (ProgramTest.Query.withinId "wiki-missing-published-pending-notice"
                                    (ProgramTest.Query.expectHasDataAttributes
                                        [ ( "data-missing-page-submission-status", "Pending review" )
                                        ]
                                    )
                                )
                          , client.clickLink 100 (Wiki.submissionDetailUrlPath "Demo" "sub_1")
                          , client.checkView 400
                                (ProgramTest.Query.expectAll
                                    [ ProgramTest.Query.withinId "wiki-submission-detail-status"
                                        (ProgramTest.Query.expectHasText "Pending review")
                                    , ProgramTest.Query.withinId "wiki-submission-detail-kind-summary"
                                        (ProgramTest.Query.expectHasText "New page: Story09NewPage")
                                    , ProgramTest.Query.withinId "wiki-submission-detail-next-steps"
                                        (ProgramTest.Query.expectHasText "trusted contributor")
                                    ]
                                )
                          , client.clickLink 100 (Wiki.mySubmissionsUrlPath "Demo")
                          , client.checkView 400
                                (ProgramTest.Query.withinId "wiki-my-submissions-page"
                                    (ProgramTest.Query.withinDataAttribute "data-my-submissions-item"
                                        "sub_1"
                                        (ProgramTest.Query.expectAll
                                            [ ProgramTest.Query.expectHasText "sub_1"
                                            , ProgramTest.Query.expectHasText "Pending review"
                                            ]
                                        )
                                    )
                                )
                          ]
                        ]
            }
        , ProgramTest.Start.bothViewports
            { baseName = "9 — cross-session: saved new-page draft still listed after logout and login"
            , config = ProgramTest.Config.demoWikiPagesOnly
            , sessionId = "session-story09-cross"
            , path = "/w/Demo/register"
            , connectClientMs = Nothing
            , clientSteps =
                \client ->
                    List.concat
                        [ [ client.input 100 (Effect.Browser.Dom.id "wiki-register-username") "story09cross"
                          , client.input 100 (Effect.Browser.Dom.id "wiki-register-password") "password12"
                          ]
                        , ProgramTest.Actions.triggerFormSubmit "wiki-register-form" client
                        , [ client.update 100 (UrlChanged submitNewPageUrl)
                          , client.input 100 (Effect.Browser.Dom.id "content-markdown-textarea") "# cross session"
                          , client.click 100 (Effect.Browser.Dom.id "wiki-submit-new-save-draft")
                          , client.checkView 400
                                (ProgramTest.Query.withinId "wiki-submit-new-save-draft-success"
                                    (ProgramTest.Query.expectHasText "Draft saved.")
                                )
                          , client.click 100 (Effect.Browser.Dom.id "wiki-logout-button")
                          , client.checkView 300
                                (ProgramTest.Query.expectHasNotId "wiki-logout-button")
                          , client.update 100 (UrlChanged { submitNewPageUrl | path = "/w/Demo/login" })
                          , client.input 100 (Effect.Browser.Dom.id "wiki-login-username") "story09cross"
                          , client.input 100 (Effect.Browser.Dom.id "wiki-login-password") "password12"
                          ]
                        , ProgramTest.Actions.triggerFormSubmit "wiki-login-form" client
                        , [ client.checkView 400
                                (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                          , client.clickLink 100 (Wiki.mySubmissionsUrlPath "Demo")
                          , client.checkView 400
                                (ProgramTest.Query.withinDataAttribute "data-my-submissions-item"
                                    "sub_1"
                                    (ProgramTest.Query.expectHasText "Draft")
                                )
                          ]
                        ]
            }
        , ProgramTest.Start.bothViewports
            { baseName = "9 — withdraw pending new page to draft; delete removes missing-page notice"
            , config = ProgramTest.Config.demoWikiPagesOnly
            , sessionId = "session-story09-withdraw-delete"
            , path = "/w/Demo/register"
            , connectClientMs = Nothing
            , clientSteps =
                \client ->
                    let
                        slugUrl : Url
                        slugUrl =
                            { protocol = Http
                            , host = "localhost"
                            , port_ = Just 8000
                            , path = "/w/Demo/submit/new"
                            , query = Just "page=Story09Wd"
                            , fragment = Nothing
                            }

                        missingUrl : Url
                        missingUrl =
                            { protocol = Http
                            , host = "localhost"
                            , port_ = Just 8000
                            , path = "/w/Demo/p/Story09Wd"
                            , query = Nothing
                            , fragment = Nothing
                            }
                    in
                    List.concat
                        [ [ client.input 100 (Effect.Browser.Dom.id "wiki-register-username") "story09wd"
                          , client.input 100 (Effect.Browser.Dom.id "wiki-register-password") "password12"
                          ]
                        , ProgramTest.Actions.triggerFormSubmit "wiki-register-form" client
                        , [ client.update 100 (UrlChanged slugUrl)
                          , client.input 100 (Effect.Browser.Dom.id "content-markdown-textarea") "# wd"
                          ]
                        , ProgramTest.Actions.triggerFormSubmit "wiki-submit-new-form" client
                        , [ client.checkView 300
                                (ProgramTest.Query.withinId "wiki-submit-new-success"
                                    (ProgramTest.Query.expectHasSubmissionId "sub_1")
                                )
                          , client.clickLink 100 (Wiki.submissionDetailUrlPath "Demo" "sub_1")
                          , client.checkView 300
                                (ProgramTest.Query.withinId "wiki-submission-detail-status"
                                    (ProgramTest.Query.expectHasText "Pending review")
                                )
                          , client.click 100 (Effect.Browser.Dom.id "wiki-submission-detail-withdraw")
                          , client.checkView 600
                                (ProgramTest.Query.withinId "wiki-submission-detail-status"
                                    (ProgramTest.Query.expectHasText "Draft")
                                )
                          , client.input 100 (Effect.Browser.Dom.id "new-markdown-editable-textarea") "# wd revised"
                          , client.click 100 (Effect.Browser.Dom.id "wiki-submission-detail-submit-for-review")
                          , client.checkView 500
                                (ProgramTest.Query.withinId "wiki-submission-detail-status"
                                    (ProgramTest.Query.expectHasText "Pending review")
                                )
                          , client.click 100 (Effect.Browser.Dom.id "wiki-submission-detail-withdraw")
                          , client.checkView 600
                                (ProgramTest.Query.withinId "wiki-submission-detail-status"
                                    (ProgramTest.Query.expectHasText "Draft")
                                )
                          , client.click 100 (Effect.Browser.Dom.id "wiki-submission-detail-delete")
                          , client.clickLink 100 (Wiki.mySubmissionsUrlPath "Demo")
                          , client.checkView 500
                                (ProgramTest.Query.withinId "wiki-my-submissions-empty"
                                    (ProgramTest.Query.expectHasText "No submissions to show here yet.")
                                )
                          ]
                        , ProgramTest.Actions.navigateToWikiHome "Demo" client
                        , [ client.update 100 (UrlChanged missingUrl)
                          , client.checkView 400
                                (ProgramTest.Query.withinId "wiki-missing-published-page"
                                    (ProgramTest.Query.expectHasNotId "wiki-missing-published-pending-notice")
                                )
                          ]
                        ]
            }
        , ProgramTest.Start.bothViewports
            { baseName = "9 — missing page without login shows no contributor draft notice"
            , config = ProgramTest.Config.demoWikiPagesOnly
            , sessionId = "session-story09-missing-anon"
            , path = "/w/Demo/p/Story09AnonMissing"
            , connectClientMs = Nothing
            , clientSteps =
                \client ->
                    [ client.checkView 400
                        (ProgramTest.Query.expectAll
                            [ ProgramTest.Query.expectHasNotId "page-published-page"
                            , ProgramTest.Query.withinId "wiki-missing-published-page"
                                (ProgramTest.Query.expectHasText "does not exist yet")
                            , ProgramTest.Query.expectHasNotId "wiki-missing-published-pending-notice"
                            ]
                        )
                    ]
            }
        ]
