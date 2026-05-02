module ProgramTest.Story59_SubmissionDetailTrustedRedirect exposing (endToEndTests)

import Effect.Browser.Dom
import ProgramTest.Actions
import ProgramTest.Config
import ProgramTest.Model
import ProgramTest.Query
import ProgramTest.Start
import Route
import Types exposing (FrontendMsg(..))
import Url exposing (Protocol(..), Url)
import Wiki


submitNewPageUrl : Url
submitNewPageUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/Demo/submit/new"
    , query = Just "page=Story59Page"
    , fragment = Nothing
    }


loginUrl : Url
loginUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/Demo/login"
    , query = Nothing
    , fragment = Nothing
    }


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    List.concat
        [ ProgramTest.Start.bothViewports
            { baseName = "59 — trusted visiting other's /submit/:id lands on review detail"
            , config = ProgramTest.Config.demoWikiPagesOnly
            , sessionId = "session-story59-trusted-submit-redirect"
            , path = "/w/Demo/register"
            , connectClientMs = Nothing
            , clientSteps =
                \client ->
                    List.concat
                        [ [ client.input 100 (Effect.Browser.Dom.id "wiki-register-username") "story59_redirect_user"
                          , client.input 100 (Effect.Browser.Dom.id "wiki-register-password") "password12"
                          ]
                        , ProgramTest.Actions.triggerFormSubmit "wiki-register-form" client
                        , [ client.checkView 400
                                (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                          , client.update 100 (UrlChanged submitNewPageUrl)
                          , client.input 100 (Effect.Browser.Dom.id "content-markdown-textarea") "# Story 59 redirect"
                          ]
                        , ProgramTest.Actions.triggerFormSubmit "wiki-submit-new-form" client
                        , [ client.checkView 400
                                (ProgramTest.Query.withinId "wiki-submit-new-success"
                                    (ProgramTest.Query.expectHasSubmissionId "sub_1")
                                )
                          ]
                        , ProgramTest.Actions.navigateToWikiHome "Demo" client
                        , [ client.click 100 (Effect.Browser.Dom.id "wiki-logout-button")
                          , client.checkView 300
                                (ProgramTest.Query.expectHasNotId "wiki-logout-button")
                          , client.update 100 (UrlChanged loginUrl)
                          ]
                        , ProgramTest.Actions.submitWikiLoginForm
                            { username = "demo_trusted_publisher"
                            , password = "password12"
                            }
                            client
                        , [ client.checkView 500
                                (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                          ]
                        , ProgramTest.Actions.navigateToPath (Wiki.submissionDetailUrlPath "Demo" "sub_1") client
                        , [ client.checkView 600
                                (ProgramTest.Query.withinId "wiki-review-detail-page"
                                    (ProgramTest.Query.expectHasDataAttributes
                                        [ ( "data-submission-id", "sub_1" )
                                        , ( "data-wiki-slug", "Demo" )
                                        ]
                                    )
                                )
                          , client.checkModel 100
                                (ProgramTest.Model.expectRoute (Route.WikiReviewDetail "Demo" "sub_1")
                                    "trusted moderator redirected from contributor submit URL"
                                )
                          ]
                        ]
            }
        , ProgramTest.Start.bothViewports
            { baseName = "59 — after contributor logout, trusted login does not reuse cached contributor submit view"
            , config = ProgramTest.Config.demoWikiPagesOnly
            , sessionId = "session-story59-logout-clears-submit-cache"
            , path = "/w/Demo/register"
            , connectClientMs = Nothing
            , clientSteps =
                \client ->
                    List.concat
                        [ [ client.input 100 (Effect.Browser.Dom.id "wiki-register-username") "story59_cache_user"
                          , client.input 100 (Effect.Browser.Dom.id "wiki-register-password") "password12"
                          ]
                        , ProgramTest.Actions.triggerFormSubmit "wiki-register-form" client
                        , [ client.update 100 (UrlChanged submitNewPageUrl)
                          , client.input 100 (Effect.Browser.Dom.id "content-markdown-textarea") "# Story 59 cache"
                          ]
                        , ProgramTest.Actions.triggerFormSubmit "wiki-submit-new-form" client
                        , [ client.checkView 400
                                (ProgramTest.Query.withinId "wiki-submit-new-success"
                                    (ProgramTest.Query.expectHasSubmissionId "sub_1")
                                )
                          , client.clickLink 100 (Wiki.submissionDetailUrlPath "Demo" "sub_1")
                          , client.checkView 400
                                (ProgramTest.Query.withinId "wiki-submission-detail-withdraw"
                                    (ProgramTest.Query.expectHasText "Withdraw (edit)")
                                )
                          , client.click 100 (Effect.Browser.Dom.id "wiki-logout-button")
                          , client.checkView 300
                                (ProgramTest.Query.expectHasNotId "wiki-logout-button")
                          ]
                        , ProgramTest.Actions.submitWikiLoginForm
                            { username = "demo_trusted_publisher"
                            , password = "password12"
                            }
                            client
                        , [ client.checkView 700
                                (ProgramTest.Query.expectAll
                                    [ ProgramTest.Query.expectHasNotId "wiki-submission-detail-withdraw"
                                    , ProgramTest.Query.withinId "wiki-review-detail-page"
                                        (ProgramTest.Query.expectHasDataAttributes
                                            [ ( "data-submission-id", "sub_1" )
                                            , ( "data-wiki-slug", "Demo" )
                                            ]
                                        )
                                    ]
                                )
                          , client.checkModel 100
                                (ProgramTest.Model.expectRoute (Route.WikiReviewDetail "Demo" "sub_1")
                                    "post-login redirect from cached submit URL becomes review detail"
                                )
                          ]
                        ]
            }
        ]
