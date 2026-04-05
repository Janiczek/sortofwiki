module ProgramTest.Story48_ConcurrentEditConflicts exposing (endToEndTests)

import Effect.Browser.Dom
import Effect.Test
import ProgramTest.Actions
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Submission
import Types exposing (FrontendMsg(..))
import Url exposing (Protocol(..), Url)
import Wiki


story48SubmitEditGuidesUrl : Url
story48SubmitEditGuidesUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/Demo/edit/Guides"
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


navigateToSubmitEditGuides :
    Effect.Test.FrontendActions toBackend FrontendMsg frontendModel toFrontend backendMsg backendModel
    -> List (Effect.Test.Action toBackend FrontendMsg frontendModel toFrontend backendMsg backendModel)
navigateToSubmitEditGuides client =
    [ client.clickLink 100 (Wiki.wikiHomeUrlPath "Demo")
    , client.clickLink 100 (Wiki.publishedPageUrlPath "Demo" "Guides")
    , client.update 100 (UrlChanged story48SubmitEditGuidesUrl)
    ]


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.startWith
        { name = "48 — one concurrent edit approved; other needs revision, withdraw, draft resubmit, then approved"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , steps =
            [ ProgramTest.Start.connectFrontend
                { sessionId = "session-story48-user-a"
                , path = "/w/Demo/register"
                , connectClientMs = Nothing
                , steps =
                    \client ->
                        List.concat
                            [ [ client.input 100 (Effect.Browser.Dom.id "wiki-register-username") "story48a"
                              , client.input 100 (Effect.Browser.Dom.id "wiki-register-password") "password12"
                              ]
                            , ProgramTest.Actions.triggerFormSubmit "wiki-register-form" client
                            , navigateToSubmitEditGuides client
                            , [ client.input 100 (Effect.Browser.Dom.id "wiki-submit-edit-markdown") editA
                              ]
                            , ProgramTest.Actions.triggerFormSubmit "wiki-submit-edit-form" client
                            , [ client.checkView 300
                                    (ProgramTest.Query.withinId "wiki-submit-edit-success"
                                        (ProgramTest.Query.expectHasSubmissionId "sub_1")
                                    )
                              ]
                            ]
                }
            , ProgramTest.Start.connectFrontend
                { sessionId = "session-story48-user-b"
                , path = "/w/Demo/register"
                , connectClientMs = Nothing
                , steps =
                    \client ->
                        List.concat
                            [ [ client.input 100 (Effect.Browser.Dom.id "wiki-register-username") "story48b"
                              , client.input 100 (Effect.Browser.Dom.id "wiki-register-password") "password12"
                              ]
                            , ProgramTest.Actions.triggerFormSubmit "wiki-register-form" client
                            , navigateToSubmitEditGuides client
                            , [ client.input 100 (Effect.Browser.Dom.id "wiki-submit-edit-markdown") editB
                              ]
                            , ProgramTest.Actions.triggerFormSubmit "wiki-submit-edit-form" client
                            , [ client.checkView 300
                                    (ProgramTest.Query.withinId "wiki-submit-edit-success"
                                        (ProgramTest.Query.expectHasSubmissionId "sub_2")
                                    )
                              ]
                            , navigateToSubmitEditGuides client
                            , [ client.input 100 (Effect.Browser.Dom.id "wiki-submit-edit-markdown") "# duplicate pending attempt"
                              ]
                            , ProgramTest.Actions.triggerFormSubmit "wiki-submit-edit-form" client
                            , [ client.checkView 300
                                    (ProgramTest.Query.withinId "wiki-submit-edit-error-text"
                                        (ProgramTest.Query.expectHasText "already have a pending edit for this page")
                                    )
                              ]
                            ]
                }
            , ProgramTest.Start.connectFrontend
                { sessionId = "session-story48-trusted"
                , path = "/"
                , connectClientMs = Nothing
                , steps =
                    \client ->
                        List.concat
                            [ ProgramTest.Actions.loginToWiki
                                { wikiSlug = "Demo"
                                , username = "demo_trusted_publisher"
                                , password = "password12"
                                }
                                client
                            , [ client.clickLink 100 (Wiki.reviewQueueUrlPath "Demo")
                              , client.clickLink 100 (Wiki.reviewDetailUrlPath "Demo" "sub_1")
                              , client.click 100 (Effect.Browser.Dom.id "wiki-review-decision-submit")
                              , client.checkView 400
                                    (ProgramTest.Query.withinId "wiki-review-approve-success"
                                        (ProgramTest.Query.expectHasText "Submission approved and published.")
                                    )
                              ]
                            ]
                }
            , ProgramTest.Start.connectFrontend
                { sessionId = "session-story48-user-b"
                , path = "/"
                , connectClientMs = Nothing
                , steps =
                    \client ->
                        List.concat
                            [ ProgramTest.Actions.loginToWiki
                                { wikiSlug = "Demo"
                                , username = "story48b"
                                , password = "password12"
                                }
                                client
                            , [ client.clickLink 100 (Wiki.mySubmissionsUrlPath "Demo")
                              , client.clickLink 100 (Wiki.submissionDetailUrlPath "Demo" "sub_2")
                              , client.checkView 500
                                    (ProgramTest.Query.withinId "wiki-submission-detail-status"
                                        (ProgramTest.Query.expectHasText "Needs revision")
                                    )
                              , client.checkView 200
                                    (ProgramTest.Query.withinId "wiki-submission-detail-reviewer-note"
                                        (ProgramTest.Query.expectHasText "Page changed after this edit was submitted")
                                    )
                              , client.checkView 2500
                                    (ProgramTest.Query.withinId "original-preview"
                                        (ProgramTest.Query.expectHasText "How to use this wiki")
                                    )
                              , client.checkView 200
                                    (ProgramTest.Query.withinId "new-markdown-readonly-textarea"
                                        (ProgramTest.Query.expectHasInputValue editB)
                                    )
                              , client.click 100 (Effect.Browser.Dom.id "wiki-submission-detail-withdraw")
                              , client.checkView 600
                                    (ProgramTest.Query.withinId "wiki-submission-detail-status"
                                        (ProgramTest.Query.expectHasText "Draft")
                                    )
                              , client.input 100 (Effect.Browser.Dom.id "new-markdown-editable-textarea") "   "
                              , client.click 100 (Effect.Browser.Dom.id "wiki-submission-detail-submit-for-review")
                              , client.checkView 200
                                    (ProgramTest.Query.withinId "wiki-submission-detail-action-error"
                                        (ProgramTest.Query.expectHasText
                                            (Submission.validationErrorToUserText Submission.BodyEmpty)
                                        )
                                    )
                              , client.input 100 (Effect.Browser.Dom.id "new-markdown-editable-textarea") editBResolved
                              , client.click 100 (Effect.Browser.Dom.id "wiki-submission-detail-submit-for-review")
                              , client.checkView 400
                                    (ProgramTest.Query.withinId "wiki-submission-detail-status"
                                        (ProgramTest.Query.expectHasText "Pending review")
                                    )
                              ]
                            ]
                }
            , ProgramTest.Start.connectFrontend
                { sessionId = "session-story48-trusted-approve-2"
                , path = "/"
                , connectClientMs = Nothing
                , steps =
                    \client ->
                        List.concat
                            [ ProgramTest.Actions.loginToWiki
                                { wikiSlug = "Demo"
                                , username = "demo_trusted_publisher"
                                , password = "password12"
                                }
                                client
                            , [ client.clickLink 100 (Wiki.reviewQueueUrlPath "Demo")
                              , client.clickLink 100 (Wiki.reviewDetailUrlPath "Demo" "sub_2")
                              , client.click 100 (Effect.Browser.Dom.id "wiki-review-decision-submit")
                              , client.checkView 400
                                    (ProgramTest.Query.withinId "wiki-review-approve-success"
                                        (ProgramTest.Query.expectHasText "Submission approved and published.")
                                    )
                              , client.clickLink 100 (Wiki.wikiHomeUrlPath "Demo")
                              , client.clickLink 100 (Wiki.publishedPageUrlPath "Demo" "Guides")
                              , client.checkView 400
                                    (ProgramTest.Query.withinPageMarkdownHeading "h1"
                                        (ProgramTest.Query.expectHasText "Story48 resolved edit B")
                                    )
                              ]
                            ]
                }
            ]
        }
    ]
