module ProgramTest.Story10_PageEditSubmission exposing (endToEndTests)

import Effect.Browser.Dom
import Expect
import ProgramTest.Actions
import ProgramTest.Config
import ProgramTest.Model
import ProgramTest.Query
import ProgramTest.Start
import Route
import Types exposing (FrontendMsg(..))
import Url exposing (Protocol(..), Url)
import Wiki


story10SubmitEditUrl : Url
story10SubmitEditUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/Demo/edit/Guides"
    , query = Nothing
    , fragment = Nothing
    }


proposedEditMarker : String
proposedEditMarker =
    "STORY10_PROPOSED_EDIT_BODY"


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "10 — submit page edit proposal; published content unchanged"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story10-edit"
        , path = "/w/Demo/register"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                List.concat
                    [ [ client.input 100 (Effect.Browser.Dom.id "wiki-register-username") "story10user"
                      , client.input 100 (Effect.Browser.Dom.id "wiki-register-password") "password12"
                      ]
                    , ProgramTest.Actions.triggerFormSubmit "wiki-register-form" client
                    , [ client.checkView 400
                            (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      , client.click 100 (Effect.Browser.Dom.id "wiki-logout-button")
                      , client.clickLink 100 (Wiki.loginUrlPath "Demo")
                      ]
                    , ProgramTest.Actions.submitWikiLoginForm
                        { username = "story10user"
                        , password = "password12"
                        }
                        client
                    , [ client.checkView 300
                            (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      , client.clickLink 100 (Wiki.wikiHomeUrlPath "Demo")
                      , client.clickLink 100 (Wiki.publishedPageUrlPath "Demo" "Guides")
                      , client.checkView 200
                            (ProgramTest.Query.withinId "wiki-page-propose-edit"
                                (ProgramTest.Query.expectHasText "Propose edit")
                            )
                      , client.update 100 (UrlChanged story10SubmitEditUrl)
                      , client.checkModel 200
                            (ProgramTest.Model.expectRoute (Route.WikiSubmitEdit "Demo" "Guides")
                                "expected submit-edit route after navigation"
                            )
                      , client.checkModel 3000
                            (\model ->
                                if
                                    String.contains "How to use this wiki" model.pageEditSubmitDraft.markdownBody
                                        && String.contains "Backlinks" model.pageEditSubmitDraft.markdownBody
                                then
                                    Ok ()

                                else
                                    Err
                                        ("expected Guides markdown in edit draft, got length "
                                            ++ String.fromInt (String.length model.pageEditSubmitDraft.markdownBody)
                                        )
                            )
                      , client.input 100 (Effect.Browser.Dom.id "wiki-submit-edit-markdown") ("# " ++ proposedEditMarker)
                      ]
                    , ProgramTest.Actions.triggerFormSubmit "wiki-submit-edit-form" client
                    , [ client.checkView 300
                            (ProgramTest.Query.withinId "wiki-submit-edit-success"
                                (ProgramTest.Query.expectHasSubmissionId "sub_1")
                            )
                      , client.clickLink 100 (Wiki.wikiHomeUrlPath "Demo")
                      , client.clickLink 100 (Wiki.publishedPageUrlPath "Demo" "Guides")
                      , client.checkView 200
                            (ProgramTest.Query.expectAll
                                [ ProgramTest.Query.withinPageMarkdownHeading "h2"
                                    (ProgramTest.Query.expectHasText "How to use this wiki")
                                , ProgramTest.Query.expectTextOccurrenceCount proposedEditMarker (\c -> c |> Expect.equal 0)
                                ]
                            )
                      ]
                    ]
        }
    ]
