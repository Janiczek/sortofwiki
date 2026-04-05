module ProgramTest.Story11_PageDeleteSubmission exposing (endToEndTests)

import Effect.Browser.Dom
import ProgramTest.Actions
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Wiki


deleteReasonMarker : String
deleteReasonMarker =
    "STORY11_DELETE_REASON"


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
                      , client.click 100 (Effect.Browser.Dom.id "wiki-register-submit")
                      , client.checkView 400
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
                      , client.click 100 (Effect.Browser.Dom.id "wiki-submit-delete-submit")
                      , client.checkView 300
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
    ]
