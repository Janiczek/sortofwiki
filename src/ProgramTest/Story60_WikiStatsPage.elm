module ProgramTest.Story60_WikiStatsPage exposing (endToEndTests)

import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Types exposing (FrontendMsg(..))
import Url exposing (Protocol(..), Url)


statsUrl : Url
statsUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/Demo/stats"
    , query = Nothing
    , fragment = Nothing
    }


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    ProgramTest.Start.bothViewports
        { baseName = "60 — wiki stats page renders public stats"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story60-wiki-stats"
        , path = "/w/Demo/p/About"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                [ client.checkView 150
                    (ProgramTest.Query.withinId "mobile-side-nav-drawer"
                        (ProgramTest.Query.withinHref "/w/Demo/stats" (ProgramTest.Query.expectHasText "Stats"))
                    )
                , client.update 100 (UrlChanged statsUrl)
                , client.checkView 400
                    (ProgramTest.Query.expectAll
                        [ ProgramTest.Query.withinId "wiki-stats-page"
                            (ProgramTest.Query.expectHasDataAttributes [ ( "data-wiki-slug", "Demo" ) ])
                        , ProgramTest.Query.expectHasText "Overview"
                        , ProgramTest.Query.expectHasText "Published pages"
                        , ProgramTest.Query.expectHasText "Top pages by in-links"
                        , ProgramTest.Query.expectHasText "Top pages by out-links"
                        , ProgramTest.Query.expectHasText "Words written"
                        , ProgramTest.Query.expectHasText "Words written (daily)"
                        , ProgramTest.Query.expectHasText "Top pages by words"
                        , ProgramTest.Query.expectHasText "Totals over time"
                        ]
                    )
                ]
        }
