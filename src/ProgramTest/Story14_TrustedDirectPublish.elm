module ProgramTest.Story14_TrustedDirectPublish exposing (endToEndTests)

import Effect.Browser.Dom
import Expect
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
    , query = Just "page=Story14TrustedPage"
    , fragment = Nothing
    }


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "14 — trusted contributor new page is public without review"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story14-trusted-new"
        , path = "/"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                List.concat
                    [ ProgramTest.Actions.loginToWiki
                        { wikiSlug = "Demo"
                        , username = "trustedpub"
                        , password = "password12"
                        }
                        client
                    , [ client.checkView 300
                            (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      , client.update 100 (UrlChanged submitNewPageUrl)
                      , client.input 100 (Effect.Browser.Dom.id "content-markdown-textarea") "# Story 14 trusted publish"
                      , client.click 100 (Effect.Browser.Dom.id "wiki-submit-new-submit")
                      , client.checkView 300
                            (ProgramTest.Query.withinPageMarkdownHeading "h1"
                                (ProgramTest.Query.expectHasText "Story 14 trusted publish")
                            )
                      , client.clickLink 100 (Wiki.wikiHomeUrlPath "Demo")
                      , client.checkView 200
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
    ]
