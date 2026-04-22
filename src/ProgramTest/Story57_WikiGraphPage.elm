module ProgramTest.Story57_WikiGraphPage exposing (endToEndTests)

import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Types exposing (FrontendMsg(..))
import Url exposing (Protocol(..), Url)


graphUrl : Url
graphUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/Demo/graph"
    , query = Nothing
    , fragment = Nothing
    }


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "57 — wiki graph page renders public page-link graph"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story57-wiki-graph"
        , path = "/w/Demo/p/About"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                [ client.checkView 150
                    (ProgramTest.Query.withinHref "/w/Demo/graph" (ProgramTest.Query.expectHasText "Graph"))
                , client.update 100 (UrlChanged graphUrl)
                , client.checkView 200
                    (ProgramTest.Query.expectAll
                        [ ProgramTest.Query.withinId "wiki-graph-page"
                            (ProgramTest.Query.expectHasDataAttributes [ ( "data-wiki-slug", "Demo" ) ])
                        , ProgramTest.Query.withinId "wiki-graphviz"
                            (ProgramTest.Query.expectHasDataAttributes
                                [ ( "data-graphviz-pages", "5" )
                                , ( "data-graphviz-edges", "11" )
                                ]
                            )
                        ]
                    )
                ]
        }
    ]
