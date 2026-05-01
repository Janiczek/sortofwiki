module ProgramTest.Story58_WikiSearch exposing (endToEndTests)

import Effect.Browser.Dom
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Types exposing (FrontendMsg(..))
import Url exposing (Protocol(..), Url)


searchUrl : Url
searchUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/Demo/search"
    , query = Just "q=contributor"
    , fragment = Nothing
    }


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    ProgramTest.Start.bothViewports
        { baseName = "58 — wiki search popup and page show matching results"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story58-wiki-search"
        , path = "/w/Demo/p/About"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                [ client.checkView 150
                    (ProgramTest.Query.withinLayoutHeader
                        (ProgramTest.Query.withinId "header-search-input" (ProgramTest.Query.expectHasInputValue ""))
                    )
                , client.input 100 (Effect.Browser.Dom.id "header-search-input") "contributor"
                , client.checkView 150
                    (ProgramTest.Query.withinId "header-search-input"
                        (ProgramTest.Query.expectHasInputValue "contributor")
                    )
                , client.update 100 (UrlChanged searchUrl)
                , client.checkView 600
                    (ProgramTest.Query.expectAll
                        [ ProgramTest.Query.withinId "wiki-search-page"
                            (ProgramTest.Query.expectHasDataAttributes [ ( "data-wiki-slug", "Demo" ) ])
                        , ProgramTest.Query.withinId "wiki-search-results"
                            (ProgramTest.Query.withinDataAttribute "data-search-page-slug" "About" (ProgramTest.Query.expectHasText "About"))
                        ]
                    )
                ]
        }
