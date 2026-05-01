module ProgramTest.Story49_MissingPageNavAndWikiLinks exposing (endToEndTests)

import Effect.Browser.Dom
import ProgramTest.Actions
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Types exposing (FrontendMsg(..))
import Url exposing (Protocol(..), Url)
import Wiki


prefillMissingPublishedPageUrl : Url
prefillMissingPublishedPageUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = Wiki.publishedPageUrlPath "Demo" "Story49PrefillSlug"
    , query = Nothing
    , fragment = Nothing
    }


submitNewNoQueryUrl : Url
submitNewNoQueryUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = Wiki.submitNewPageUrlPath "Demo"
    , query = Nothing
    , fragment = Nothing
    }


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    List.concat
        [ ProgramTest.Start.bothViewports
        { baseName = "49 — [[...]] to missing published page is red on MarkdownPlayground"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story49-red-wikilink"
        , path = "/w/Demo/p/MarkdownPlayground"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                [ client.checkView 100
                    (ProgramTest.Query.withinTagAndHref "a"
                        "/w/Demo/p/Story49MissingPage"
                        (ProgramTest.Query.expectHasClass "!text-red-700")
                    )
                ]
        }
    , ProgramTest.Start.bothViewports
        { baseName = "49 — submit/new?page= shows page slug read-only from URL"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story49-submit-new-prefill"
        , path = "/w/Demo/register"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                List.concat
                    [ [ client.input 100 (Effect.Browser.Dom.id "wiki-register-username") "story49prefilluser"
                      , client.input 100 (Effect.Browser.Dom.id "wiki-register-password") "password12"
                      ]
                    , ProgramTest.Actions.triggerFormSubmit "wiki-register-form" client
                    , [ client.checkView 400
                            (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      , client.update 100 (UrlChanged prefillMissingPublishedPageUrl)
                      , client.clickLink 100 (Wiki.submitNewPageUrlPathWithSuggestedSlug "Demo" "Story49PrefillSlug")
                      , client.checkView 100
                            (ProgramTest.Query.withinId "slug-input"
                                (ProgramTest.Query.expectAll
                                    [ ProgramTest.Query.expectHasInputValue "Story49PrefillSlug"
                                    , ProgramTest.Query.expectHasReadonly
                                    ]
                                )
                            )
                      ]
                    ]
        }
    , ProgramTest.Start.bothViewports
        { baseName = "49 — diacritic wiki link keeps raw Unicode slug and opens page route"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story49-diacritic-wikilink-nav"
        , path = "/w/Demo/p/MarkdownPlayground"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                [ client.checkView 100
                    (ProgramTest.Query.withinTagAndHref "a"
                        "/w/Demo/p/Návsí"
                        (ProgramTest.Query.expectHasClass "!text-red-700")
                    )
                , client.clickLink 100 "/w/Demo/p/Návsí"
                , client.checkView 100
                    (ProgramTest.Query.withinId "wiki-missing-published-page"
                        (ProgramTest.Query.expectHasDataAttributes
                            [ ( "data-wiki-slug", "Demo" )
                            , ( "data-page-slug", "Návsí" )
                            ]
                        )
                    )
                ]
        }
    , ProgramTest.Start.bothViewports
        { baseName = "49 — submit/new without ?page= leaves page slug editable"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story49-submit-new-editable-slug"
        , path = "/w/Demo/register"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                List.concat
                    [ [ client.input 100 (Effect.Browser.Dom.id "wiki-register-username") "story49editableslug"
                      , client.input 100 (Effect.Browser.Dom.id "wiki-register-password") "password12"
                      ]
                    , ProgramTest.Actions.triggerFormSubmit "wiki-register-form" client
                    , [ client.checkView 400
                            (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      , client.update 100 (UrlChanged submitNewNoQueryUrl)
                      , client.checkView 100
                            (ProgramTest.Query.withinId "slug-input"
                                ProgramTest.Query.expectDoesNotHaveReadonly
                            )
                      ]
                    ]
        }
    , ProgramTest.Start.bothViewports
        { baseName = "49 — missing-page create link targets submit/new with page hint"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story49-missing-create-href"
        , path = "/w/Demo/p/Story49MissingTargetPage"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                [ client.checkView 100
                    (\root ->
                        let
                            expected : String
                            expected =
                                Wiki.submitNewPageUrlPathWithSuggestedSlug "Demo" "Story49MissingTargetPage"
                        in
                        root
                            |> ProgramTest.Query.withinId "wiki-missing-published-login-link"
                                (ProgramTest.Query.expectHasHref (Wiki.loginUrlPathWithRedirect "Demo" expected))
                    )
                ]
        }
    , ProgramTest.Start.bothViewports
        { baseName = "49 — missing published page shows Create page in right nav"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story49-sidebar-create"
        , path = "/w/Demo/p/Story49SidebarMissingPage"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                [ client.checkView 100
                    (\root ->
                        let
                            expected : String
                            expected =
                                Wiki.submitNewPageUrlPathWithSuggestedSlug "Demo" "Story49SidebarMissingPage"
                        in
                        root
                            |> ProgramTest.Query.withinId "page-create-link"
                                (ProgramTest.Query.expectAll
                                    [ ProgramTest.Query.expectHasText "Create page"
                                    , ProgramTest.Query.expectHasHref expected
                                    ]
                                )
                    )
                ]
        }
    , ProgramTest.Start.bothViewports
        { baseName = "49 — missing published page shows backlinks in right nav"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story49-sidebar-backlinks"
        , path = "/w/Demo/p/Story49MissingPage"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                [ client.checkView 200
                    (ProgramTest.Query.expectBacklinks "Demo" [ "MarkdownPlayground" ])
                ]
        }
    , ProgramTest.Start.bothViewports
        { baseName = "49 — missing published page shows immediate page graph on /p/ route"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story49-missing-page-graph"
        , path = "/w/Demo/p/TodoGap"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                [ client.checkView 200
                    (ProgramTest.Query.withinId "wiki-missing-published-page"
                        (ProgramTest.Query.withinId "wiki-missing-published-page-graph"
                            (ProgramTest.Query.withinId "wiki-missing-published-graph"
                                (ProgramTest.Query.expectHasDataAttributes [])
                            )
                        )
                    )
                ]
        }
        ]
