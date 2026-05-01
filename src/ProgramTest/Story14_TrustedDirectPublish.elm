module ProgramTest.Story14_TrustedDirectPublish exposing (endToEndTests)

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


submitNewPageUrl : Url
submitNewPageUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/Demo/submit/new"
    , query = Just "page=Story14TrustedPage"
    , fragment = Nothing
    }


submitNewPageUrlAfterDraft : Url
submitNewPageUrlAfterDraft =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/Demo/submit/new"
    , query = Just "page=Story14TrustedDraftThenLive"
    , fragment = Nothing
    }


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    List.concat
        [ ProgramTest.Start.bothViewports
        { baseName = "14 — trusted contributor new page is public without review"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story14-trusted-new"
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
                      , client.update 100 (UrlChanged submitNewPageUrl)
                      , client.checkView 100
                            (ProgramTest.Query.withinId "wiki-submit-new-submit"
                                (ProgramTest.Query.expectHasText "Create")
                            )
                      , client.input 100 (Effect.Browser.Dom.id "content-markdown-textarea") "# Story 14 trusted publish"
                      ]
                    , ProgramTest.Actions.triggerFormSubmit "wiki-submit-new-form" client
                    , [ client.checkView 300
                            (ProgramTest.Query.withinPageMarkdownHeading "h1"
                                (ProgramTest.Query.expectHasText "Story 14 trusted publish")
                            )
                      ]
                    , ProgramTest.Actions.navigateToWikiHome "Demo" client
                    , [ client.checkView 200
                            (ProgramTest.Query.withinId "wiki-home-page-slugs"
                                (ProgramTest.Query.expectDataAttributeOccurrenceCount "data-page-slug" "Story14TrustedPage" (\c -> c |> Expect.equal 1))
                            )
                      , client.clickLink 100 (Wiki.publishedPageUrlPath "Demo" "Story14TrustedPage")
                      , client.checkView 200
                            (ProgramTest.Query.withinPageMarkdownHeading "h1"
                                (ProgramTest.Query.expectHasText "Story 14 trusted publish")
                            )
                      ]
                    ]
        }
    , ProgramTest.Start.bothViewports
        { baseName = "14 — trusted saves new-page draft then Create still publishes immediately"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story14-trusted-draft-create"
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
                      , client.update 100 (UrlChanged submitNewPageUrlAfterDraft)
                      , client.checkView 100
                            (ProgramTest.Query.withinId "wiki-submit-new-submit"
                                (ProgramTest.Query.expectHasText "Create")
                            )
                      , client.input 100 (Effect.Browser.Dom.id "content-markdown-textarea") "# Story 14 draft then live"
                      , client.click 100 (Effect.Browser.Dom.id "wiki-submit-new-save-draft")
                      , client.checkView 400
                            (ProgramTest.Query.withinId "wiki-submit-new-save-draft-success"
                                (ProgramTest.Query.expectHasText "Draft saved.")
                            )
                      ]
                    , ProgramTest.Actions.triggerFormSubmit "wiki-submit-new-form" client
                    , [ client.checkView 400
                            (ProgramTest.Query.withinPageMarkdownHeading "h1"
                                (ProgramTest.Query.expectHasText "Story 14 draft then live")
                            )
                      ]
                    , ProgramTest.Actions.navigateToWikiHome "Demo" client
                    , [ client.checkView 200
                            (ProgramTest.Query.withinId "wiki-home-page-slugs"
                                (ProgramTest.Query.expectDataAttributeOccurrenceCount "data-page-slug" "Story14TrustedDraftThenLive" (\c -> c |> Expect.equal 1))
                            )
                      ]
                    ]
        }
    , ProgramTest.Start.bothViewports
        { baseName = "14 — trusted direct page edit redirects to published page"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story14-trusted-edit-redirect"
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
                      ]
                    , ProgramTest.Actions.navigateToWikiSubmitEdit "Demo" "Guides" client
                    , [ client.checkModel 200
                            (ProgramTest.Model.expectRoute (Route.WikiSubmitEdit "Demo" "Guides")
                                "expected submit-edit route"
                            )
                      , client.checkModel 3000
                            (\model ->
                                if String.contains "How to use this wiki" model.pageEditSubmitDraft.markdownBody then
                                    Ok ()

                                else
                                    Err
                                        ("expected Guides markdown in edit draft, got length "
                                            ++ String.fromInt (String.length model.pageEditSubmitDraft.markdownBody)
                                        )
                            )
                      ]
                    , ProgramTest.Actions.submitWikiEditForm "Demo" "Guides" "# Story 14 trusted edit redirect\n\nEdited body." client
                    ]
        }
        ]
