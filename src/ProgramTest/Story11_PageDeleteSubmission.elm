module ProgramTest.Story11_PageDeleteSubmission exposing (endToEndTests)

import Effect.Browser.Dom
import ProgramTest.Actions
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Submission
import Wiki


deleteReasonMarker : String
deleteReasonMarker =
    "STORY11_DELETE_REASON"


immediateDeleteReasonMarker : String
immediateDeleteReasonMarker =
    "STORY11_IMMEDIATE_DELETE_REASON"


requiredDeletionReasonUserText : String
requiredDeletionReasonUserText =
    Submission.deleteReasonErrorToUserText Submission.ReasonRequired


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "11 — submit page deletion request; published page unchanged"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story11-delete"
        , path = "/w/Demo/register"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                List.concat
                    [ [ client.input 100 (Effect.Browser.Dom.id "wiki-register-username") "story11user"
                      , client.input 100 (Effect.Browser.Dom.id "wiki-register-password") "password12"
                      ]
                    , ProgramTest.Actions.triggerFormSubmit "wiki-register-form" client
                    , [ client.checkView 400
                            (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      , client.click 100 (Effect.Browser.Dom.id "wiki-logout-button")
                      , client.clickLink 100 (Wiki.loginUrlPath "Demo")
                      ]
                    , ProgramTest.Actions.submitWikiLoginForm
                        { username = "story11user"
                        , password = "password12"
                        }
                        client
                    , [ client.checkView 300
                            (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      , client.clickLink 100 (Wiki.wikiHomeUrlPath "Demo")
                      , client.clickLink 100 (Wiki.publishedPageUrlPath "Demo" "Guides")
                      , client.checkView 200
                            (ProgramTest.Query.withinId "wiki-page-request-deletion"
                                (ProgramTest.Query.expectHasText "Request deletion")
                            )
                      , client.clickLink 100 (Wiki.submitDeleteUrlPath "Demo" "Guides")
                      , client.checkView 100
                            (ProgramTest.Query.withinId "wiki-submit-delete-page"
                                (ProgramTest.Query.expectHasDataAttributes
                                    [ ( "data-wiki-slug", "Demo" )
                                    , ( "data-page-slug", "Guides" )
                                    ]
                                )
                            )
                      , client.input 100 (Effect.Browser.Dom.id "wiki-submit-delete-reason") deleteReasonMarker
                      ]
                    , ProgramTest.Actions.triggerFormSubmit "wiki-submit-delete-form" client
                    , [ client.checkView 300
                            (ProgramTest.Query.withinId "wiki-submit-delete-success"
                                (ProgramTest.Query.expectHasSubmissionId "sub_1")
                            )
                      , client.clickLink 100 (Wiki.wikiHomeUrlPath "Demo")
                      , client.clickLink 100 (Wiki.publishedPageUrlPath "Demo" "Guides")
                      , client.checkView 200
                            (ProgramTest.Query.withinPageMarkdownHeading "h2"
                                (ProgramTest.Query.expectHasText "How to use this wiki")
                            )
                      ]
                    ]
        }
    , ProgramTest.Start.start
        { name = "11 — trusted contributor deletes published page immediately (no submission)"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story11-trusted-immediate-delete"
        , path = "/"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                List.concat
                    [ ProgramTest.Actions.loginToWiki
                        { wikiSlug = "Demo"
                        , username = "demo_trusted_publisher"
                        , password = "password12"
                        }
                        client
                    , [ client.checkView 300
                            (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      , client.clickLink 100 (Wiki.wikiHomeUrlPath "Demo")
                      ]
                    , ProgramTest.Actions.navigateToPath (Wiki.publishedPageUrlPath "Demo" "About") client
                    , [ client.checkView 200
                            (ProgramTest.Query.withinId "wiki-page-delete-published"
                                (ProgramTest.Query.expectHasText "Delete page")
                            )
                      , client.clickLink 100 (Wiki.submitDeleteUrlPath "Demo" "About")
                      , client.checkView 100
                            (ProgramTest.Query.withinId "wiki-submit-delete-page"
                                (ProgramTest.Query.expectAll
                                    [ ProgramTest.Query.expectHasText "immediately"
                                    , ProgramTest.Query.expectHasNotId "wiki-submit-delete-save-draft"
                                    ]
                                )
                            )
                      , client.checkView 100
                            (ProgramTest.Query.withinId "wiki-submit-delete-submit"
                                (ProgramTest.Query.expectHasText "Delete page")
                            )
                      , client.input 100 (Effect.Browser.Dom.id "wiki-submit-delete-reason") immediateDeleteReasonMarker
                      , client.click 100 (Effect.Browser.Dom.id "wiki-submit-delete-submit")
                      , client.checkView 300
                            (ProgramTest.Query.withinId "wiki-submit-delete-success"
                                (ProgramTest.Query.expectAll
                                    [ ProgramTest.Query.expectHasText "was removed"
                                    , ProgramTest.Query.expectHasNotText "Submitted for review"
                                    ]
                                )
                            )
                      ]
                    , ProgramTest.Actions.navigateToPath (Wiki.publishedPageUrlPath "Demo" "About") client
                    , [ client.checkView 200
                            (ProgramTest.Query.withinId "wiki-missing-published-page"
                                (ProgramTest.Query.expectHasText "The page \"About\" does not exist yet.")
                            )
                      ]
                    ]
        }
    , ProgramTest.Start.start
        { name = "11 — wiki admin deletes published page immediately (no submission)"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story11-admin-immediate-delete"
        , path = "/"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                List.concat
                    [ ProgramTest.Actions.loginToWiki
                        { wikiSlug = "Demo"
                        , username = "demo_wiki_admin"
                        , password = "password12"
                        }
                        client
                    , [ client.checkView 300
                            (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      , client.clickLink 100 (Wiki.wikiHomeUrlPath "Demo")
                      ]
                    , ProgramTest.Actions.navigateToPath (Wiki.publishedPageUrlPath "Demo" "MarkdownPlayground") client
                    , [ client.checkView 200
                            (ProgramTest.Query.withinId "wiki-page-delete-published"
                                (ProgramTest.Query.expectHasText "Delete page")
                            )
                      , client.clickLink 100 (Wiki.submitDeleteUrlPath "Demo" "MarkdownPlayground")
                      , client.checkView 100
                            (ProgramTest.Query.withinId "wiki-submit-delete-page"
                                (ProgramTest.Query.expectHasNotId "wiki-submit-delete-save-draft")
                            )
                      , client.input 100 (Effect.Browser.Dom.id "wiki-submit-delete-reason") immediateDeleteReasonMarker
                      , client.click 100 (Effect.Browser.Dom.id "wiki-submit-delete-submit")
                      , client.checkView 300
                            (ProgramTest.Query.withinId "wiki-submit-delete-success"
                                (ProgramTest.Query.expectHasText "was removed")
                            )
                      ]
                    , ProgramTest.Actions.navigateToPath (Wiki.publishedPageUrlPath "Demo" "MarkdownPlayground") client
                    , [ client.checkView 200
                            (ProgramTest.Query.withinId "wiki-missing-published-page"
                                (ProgramTest.Query.expectHasText "The page \"MarkdownPlayground\" does not exist yet.")
                            )
                      ]
                    ]
        }
    , ProgramTest.Start.start
        { name = "11 — contributor deletion request requires non-empty reason"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story11-untrusted-reason-required"
        , path = "/w/Demo/register"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                List.concat
                    [ [ client.input 100 (Effect.Browser.Dom.id "wiki-register-username") "story11reasonreq"
                      , client.input 100 (Effect.Browser.Dom.id "wiki-register-password") "password12"
                      ]
                    , ProgramTest.Actions.triggerFormSubmit "wiki-register-form" client
                    , [ client.checkView 400
                            (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      , client.click 100 (Effect.Browser.Dom.id "wiki-logout-button")
                      , client.clickLink 100 (Wiki.loginUrlPath "Demo")
                      ]
                    , ProgramTest.Actions.submitWikiLoginForm
                        { username = "story11reasonreq"
                        , password = "password12"
                        }
                        client
                    , [ client.checkView 300
                            (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      , client.clickLink 100 (Wiki.wikiHomeUrlPath "Demo")
                      , client.clickLink 100 (Wiki.publishedPageUrlPath "Demo" "Guides")
                      , client.clickLink 100 (Wiki.submitDeleteUrlPath "Demo" "Guides")
                      , client.checkView 100
                            (ProgramTest.Query.withinId "wiki-submit-delete-page"
                                (ProgramTest.Query.withinId "wiki-submit-delete-save-draft"
                                    (ProgramTest.Query.expectHasText "Save draft")
                                )
                            )
                      ]
                    , ProgramTest.Actions.triggerFormSubmit "wiki-submit-delete-form" client
                    , [ client.checkView 100
                            (ProgramTest.Query.withinId "wiki-submit-delete-error"
                                (ProgramTest.Query.withinId "wiki-submit-delete-error-text"
                                    (ProgramTest.Query.expectHasText requiredDeletionReasonUserText)
                                )
                            )
                      ]
                    ]
        }
    , ProgramTest.Start.start
        { name = "11 — trusted immediate delete requires non-empty reason"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story11-trusted-reason-required"
        , path = "/"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                List.concat
                    [ ProgramTest.Actions.loginToWiki
                        { wikiSlug = "Demo"
                        , username = "demo_trusted_publisher"
                        , password = "password12"
                        }
                        client
                    , [ client.checkView 300
                            (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      , client.clickLink 100 (Wiki.wikiHomeUrlPath "Demo")
                      ]
                    , ProgramTest.Actions.navigateToPath (Wiki.publishedPageUrlPath "Demo" "About") client
                    , [ client.checkView 200
                            (ProgramTest.Query.withinId "wiki-page-delete-published"
                                (ProgramTest.Query.expectHasText "Delete page")
                            )
                      , client.clickLink 100 (Wiki.submitDeleteUrlPath "Demo" "About")
                      , client.checkView 100
                            (ProgramTest.Query.withinId "wiki-submit-delete-submit"
                                (ProgramTest.Query.expectHasText "Delete page")
                            )
                      , client.click 100 (Effect.Browser.Dom.id "wiki-submit-delete-submit")
                      , client.checkView 100
                            (ProgramTest.Query.withinId "wiki-submit-delete-error"
                                (ProgramTest.Query.withinId "wiki-submit-delete-error-text"
                                    (ProgramTest.Query.expectHasText requiredDeletionReasonUserText)
                                )
                            )
                      ]
                    ]
        }
    , ProgramTest.Start.start
        { name = "11 — wiki admin immediate delete requires non-empty reason"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story11-admin-reason-required"
        , path = "/"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                List.concat
                    [ ProgramTest.Actions.loginToWiki
                        { wikiSlug = "Demo"
                        , username = "demo_wiki_admin"
                        , password = "password12"
                        }
                        client
                    , [ client.checkView 300
                            (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      , client.clickLink 100 (Wiki.wikiHomeUrlPath "Demo")
                      ]
                    , ProgramTest.Actions.navigateToPath (Wiki.publishedPageUrlPath "Demo" "MarkdownPlayground") client
                    , [ client.checkView 200
                            (ProgramTest.Query.withinId "wiki-page-delete-published"
                                (ProgramTest.Query.expectHasText "Delete page")
                            )
                      , client.clickLink 100 (Wiki.submitDeleteUrlPath "Demo" "MarkdownPlayground")
                      , client.checkView 100
                            (ProgramTest.Query.withinId "wiki-submit-delete-submit"
                                (ProgramTest.Query.expectHasText "Delete page")
                            )
                      , client.click 100 (Effect.Browser.Dom.id "wiki-submit-delete-submit")
                      , client.checkView 100
                            (ProgramTest.Query.withinId "wiki-submit-delete-error"
                                (ProgramTest.Query.withinId "wiki-submit-delete-error-text"
                                    (ProgramTest.Query.expectHasText requiredDeletionReasonUserText)
                                )
                            )
                      ]
                    ]
        }
    ]
