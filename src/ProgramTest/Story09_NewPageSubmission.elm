module ProgramTest.Story09_NewPageSubmission exposing (endToEndTests)

import Effect.Browser.Dom
import Expect
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
    [ ProgramTest.Start.start
        { name = "9 — submit new page draft stays off public index"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story09-submit"
        , path = "/w/Demo/register"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                [ client.input 100 (Effect.Browser.Dom.id "wiki-register-username") "story09user"
                , client.input 100 (Effect.Browser.Dom.id "wiki-register-password") "password12"
                , client.click 100 (Effect.Browser.Dom.id "wiki-register-submit")
                , client.checkView 400
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
                , client.input 100 (Effect.Browser.Dom.id "content-markdown-textarea") "# Story 09 page"
                , client.click 100 (Effect.Browser.Dom.id "wiki-submit-new-submit")
                , client.checkView 300
                    (ProgramTest.Query.withinId "wiki-submit-new-success"
                        (ProgramTest.Query.expectHasSubmissionId "sub_1")
                    )
                , client.clickLink 100 (Wiki.wikiHomeUrlPath "Demo")
                , client.checkView 200
                    (ProgramTest.Query.withinId "wiki-home-page-slugs"
                        (ProgramTest.Query.expectDataAttributeOccurrenceCount "data-page-slug" "Story09NewPage" (\c -> c |> Expect.equal 0))
                    )
                , client.update 100 (UrlChanged pendingPageUrl)
                , client.checkView 200
                    (ProgramTest.Query.withinLayoutHeader
                        (ProgramTest.Query.expectAll
                            [ ProgramTest.Query.expectHasText ": Create?"
                            , ProgramTest.Query.expectHasText "Story09NewPage"
                            ]
                        )
                    )
                ]
        }
    ]
