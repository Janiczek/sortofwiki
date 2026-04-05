module ProgramTest.Story12_SubmissionStatus exposing (endToEndTests)

import Effect.Browser.Dom
import ProgramTest.Actions
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Types exposing (FrontendMsg(..))
import Url exposing (Protocol(..), Url)
import Wiki


submitNewPageUrl : Url
submitNewPageUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/Demo/submit/new"
    , query = Just "page=Story12Page"
    , fragment = Nothing
    }


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "12 — contributor sees Pending on new submission detail"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story12-pending"
        , path = "/w/Demo/register"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                List.concat
                    [ [ client.input 100 (Effect.Browser.Dom.id "wiki-register-username") "story12user"
                      , client.input 100 (Effect.Browser.Dom.id "wiki-register-password") "password12"
                      ]
                    , ProgramTest.Actions.triggerFormSubmit "wiki-register-form" client
                    , [ client.checkView 400
                            (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      , client.update 100 (UrlChanged submitNewPageUrl)
                      , client.input 100 (Effect.Browser.Dom.id "content-markdown-textarea") "# Story 12"
                      ]
                    , ProgramTest.Actions.triggerFormSubmit "wiki-submit-new-form" client
                    , [ client.checkView 300
                            (ProgramTest.Query.withinId "wiki-submit-new-success"
                                (ProgramTest.Query.expectHasSubmissionId "sub_1")
                            )
                      , client.clickLink 100 (Wiki.submissionDetailUrlPath "Demo" "sub_1")
                      , client.checkView 400
                            (ProgramTest.Query.withinId "wiki-submission-detail-status"
                                (ProgramTest.Query.expectHasText "Pending review")
                            )
                      , client.checkView 100
                            (ProgramTest.Query.withinId "wiki-submission-detail-kind-summary"
                                (ProgramTest.Query.expectHasText "New page: Story12Page")
                            )
                      , client.checkView 100
                            (ProgramTest.Query.withinId "wiki-submission-detail-next-steps"
                                (ProgramTest.Query.expectHasText "trusted contributor")
                            )
                      , client.checkView 100
                            (ProgramTest.Query.withinId "original-markdown-readonly-textarea"
                                ProgramTest.Query.expectHasReadonly
                            )
                      , client.checkView 100
                            (ProgramTest.Query.withinId "new-markdown-readonly-textarea"
                                ProgramTest.Query.expectHasReadonly
                            )
                      , client.checkView 100
                            (ProgramTest.Query.withinId "wiki-submission-detail-withdraw"
                                (ProgramTest.Query.expectHasText "Withdraw (edit)")
                            )
                      ]
                    ]
        }
    , ProgramTest.Start.start
        { name = "12 — seeded demo user sees Rejected on sub_3 (log in as demo_contributor / password12)"
        , config = ProgramTest.Config.demoWikiWithModerationSeeds
        , sessionId = "session-story12-seed-rejected"
        , path = "/"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                List.concat
                    [ ProgramTest.Actions.loginToWiki
                        { wikiSlug = "Demo"
                        , username = "demo_contributor"
                        , password = "password12"
                        }
                        client
                    , [ client.checkView 300
                            (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      , client.clickLink 100 (Wiki.mySubmissionsUrlPath "Demo")
                      , client.clickLink 100 (Wiki.submissionDetailUrlPath "Demo" "sub_3")
                      , client.checkView 400
                            (ProgramTest.Query.withinId "wiki-submission-detail-status"
                                (ProgramTest.Query.expectHasText "Rejected")
                            )
                      , client.checkView 100
                            (ProgramTest.Query.withinId "wiki-submission-detail-kind-summary"
                                (ProgramTest.Query.expectHasText "New page: SeedRejected")
                            )
                      ]
                    ]
        }
    ]
