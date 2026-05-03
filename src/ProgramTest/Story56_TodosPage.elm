module ProgramTest.Story56_TodosPage exposing (endToEndTests)

import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Types exposing (FrontendMsg(..))
import Url exposing (Protocol(..), Url)


homeUrl : Url
homeUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/Demo/p/Home"
    , query = Nothing
    , fragment = Nothing
    }


todosUrl : Url
todosUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/Demo/todos"
    , query = Nothing
    , fragment = Nothing
    }


markdownPlaygroundUrl : Url
markdownPlaygroundUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/Demo/p/MarkdownPlayground"
    , query = Nothing
    , fragment = Nothing
    }


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    ProgramTest.Start.bothViewports
        { baseName = "56 — TODO markers render inline, show in rail, and aggregate on wiki TODOs page"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story56-todos"
        , path = "/w/Demo/p/About"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                [ client.checkView 150
                    (ProgramTest.Query.expectAll
                        [ ProgramTest.Query.withinHref "/w/Demo/todos" (ProgramTest.Query.expectHasText "TODOs")
                        , ProgramTest.Query.withinId "page-markdown"
                            (ProgramTest.Query.withinDataAttribute "data-todo-text"
                                "explain contributor roles"
                                (ProgramTest.Query.expectHasText "TODO: explain contributor roles")
                            )
                        , ProgramTest.Query.withinId "page-todos"
                            (ProgramTest.Query.expectHasText "explain contributor roles")
                        ]
                    )
                , client.update 100 (UrlChanged markdownPlaygroundUrl)
                , client.checkView 150
                    (ProgramTest.Query.withinId "page-todos"
                        (ProgramTest.Query.expectHasText "table row with wikilink pipe")
                    )
                , client.update 100 (UrlChanged homeUrl)
                , client.checkView 150 (ProgramTest.Query.expectHasNotId "page-todos")
                , client.update 100 (UrlChanged todosUrl)
                , client.checkView 200
                    (ProgramTest.Query.expectAll
                        [ ProgramTest.Query.withinId "wiki-todos-table"
                            (ProgramTest.Query.expectHasTexts
                                [ "explain contributor roles"
                                , "About"
                                , "add contributor examples"
                                , "MarkdownPlayground"
                                , "table row with wikilink pipe"
                                , "TodoGap"
                                ]
                            )
                        , ProgramTest.Query.withinId "wiki-todos-table"
                            (ProgramTest.Query.withinDataAttribute "data-missing-page-slug"
                                "TodoGap"
                                (ProgramTest.Query.expectHasTexts [ "TodoGap", "About", "MarkdownPlayground" ])
                            )
                        , ProgramTest.Query.withinHref "/w/Demo/p/TodoGap"
                            (ProgramTest.Query.expectHasClass "!text-red-700")
                        ]
                    )
                ]
        }
