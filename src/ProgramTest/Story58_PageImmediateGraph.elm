module ProgramTest.Story58_PageImmediateGraph exposing (endToEndTests)

import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Types exposing (FrontendMsg(..))
import Url exposing (Protocol(..), Url)


pageGraphUrl : Url
pageGraphUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/Demo/pg/About"
    , query = Nothing
    , fragment = Nothing
    }


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    ProgramTest.Start.bothViewports
        { baseName = "58 — page immediate graph link and page render"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story58-page-immediate-graph"
        , path = "/w/Demo/p/About"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                [ client.checkView 150
                    (ProgramTest.Query.expectAll
                        [ ProgramTest.Query.withinId "page-immediate-graph-link"
                            (ProgramTest.Query.expectHasTexts [ "Page graph" ])
                        , ProgramTest.Query.withinHref "/w/Demo/pg/About"
                            (ProgramTest.Query.expectHasTexts [ "Page graph" ])
                        ]
                    )
                , client.update 100 (UrlChanged pageGraphUrl)
                , client.checkView 250
                    (ProgramTest.Query.expectAll
                        [ ProgramTest.Query.withinId "page-immediate-graph-page"
                            (ProgramTest.Query.expectHasDataAttributes
                                [ ( "data-wiki-slug", "Demo" )
                                , ( "data-page-slug", "About" )
                                ]
                            )
                        , ProgramTest.Query.withinHref "/w/Demo/p/About"
                            (ProgramTest.Query.expectHasTexts [ "Page" ])
                        , ProgramTest.Query.withinId "page-immediate-graphviz"
                            (ProgramTest.Query.expectHasDataAttributes [])
                        ]
                    )
                ]
        }
