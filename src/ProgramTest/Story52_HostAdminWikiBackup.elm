module ProgramTest.Story52_HostAdminWikiBackup exposing (endToEndTests)

import BackendDataExport
import Effect.Browser.Dom
import Env
import ProgramTest.Actions
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Types exposing (FrontendMsg(..))
import Url exposing (Protocol(..), Url)
import Wiki


story52ImportedWikiSlug : Wiki.Slug
story52ImportedWikiSlug =
    "Demo"


story52ImportedWikiFixtureJson : String
story52ImportedWikiFixtureJson =
    case
        BackendDataExport.encodeWikiSnapshotToJsonString
            story52ImportedWikiSlug
            (ProgramTest.Config.replayInitStepsOntoModel ProgramTest.Config.demoWikiPagesSteps)
    of
        Just json ->
            json

        Nothing ->
            "{}"


story52ImportedWikiHomeUrl : Url
story52ImportedWikiHomeUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = Wiki.wikiHomeUrlPath story52ImportedWikiSlug
    , query = Nothing
    , fragment = Nothing
    }


story52HostAdminUrl : Url
story52HostAdminUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/admin"
    , query = Nothing
    , fragment = Nothing
    }


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "52 — host admin per-wiki JSON backup buttons on /admin/wikis"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story52-wiki-backup"
        , path = "/admin"
        , connectClientMs = Just 200
        , clientSteps =
            \client ->
                List.concat
                    [ [ client.input 100 (Effect.Browser.Dom.id "host-admin-login-password") Env.hostAdminPassword
                      ]
                    , ProgramTest.Actions.triggerFormSubmit "host-admin-login-form" client
                    , [ client.checkView 300
                            (ProgramTest.Query.withinHostAdminWikiRow "Demo"
                                (ProgramTest.Query.expectHasText "Export JSON")
                            )
                      , client.checkView 100
                            (ProgramTest.Query.withinHostAdminWikiRow "Demo"
                                (ProgramTest.Query.expectHasText "Import (replace)")
                            )
                      ]
                    ]
        }
    , ProgramTest.Start.start
        { name = "52 — importing missing wiki clears stale not-found cache"
        , config = ProgramTest.Config.emptyConfig
        , sessionId = "session-story52-import-missing-wiki"
        , path = Wiki.wikiHomeUrlPath story52ImportedWikiSlug
        , connectClientMs = Just 200
        , clientSteps =
            \client ->
                List.concat
                    [ [ client.checkView 300
                            (ProgramTest.Query.withinId "wiki-not-found-page"
                                (ProgramTest.Query.expectHasText "doesn't exist")
                            )
                      , client.update 100 (UrlChanged story52HostAdminUrl)
                      ]
                    , ProgramTest.Actions.submitHostAdminLoginFormViaFormSubmit Env.hostAdminPassword client
                    , [ client.checkView 300
                            (ProgramTest.Query.withinId "host-admin-wikis-list"
                                (ProgramTest.Query.expectHasText "No wikis present")
                            )
                      , client.update 100 (HostAdminWikisDataImportFileRead (Ok story52ImportedWikiFixtureJson))
                      , client.checkView 400
                            (ProgramTest.Query.withinHostAdminWikiRow story52ImportedWikiSlug
                                (ProgramTest.Query.expectHasText "Demo Wiki")
                            )
                      , client.update 100
                            (UrlChanged
                                { story52ImportedWikiHomeUrl
                                    | path = "/"
                                }
                            )
                      , client.checkView 300
                            (ProgramTest.Query.withinWikiCatalogRow story52ImportedWikiSlug
                                (ProgramTest.Query.expectHasText "Demo Wiki")
                            )
                      ]
                    , ProgramTest.Actions.navigateToWikiHome story52ImportedWikiSlug client
                    , [ client.checkView 300
                            (ProgramTest.Query.expectAll
                                [ ProgramTest.Query.expectWikiHomePageShowsSlug story52ImportedWikiSlug
                                , ProgramTest.Query.withinId "wiki-home-page"
                                    (ProgramTest.Query.expectHasText "Home")
                                ]
                            )
                      , client.checkView 300
                            (ProgramTest.Query.expectHasNotId "wiki-not-found-page")
                      ]
                    ]
        }
    ]
