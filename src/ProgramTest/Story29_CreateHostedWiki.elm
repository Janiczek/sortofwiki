module ProgramTest.Story29_CreateHostedWiki exposing (endToEndTests)

import Effect.Browser.Dom
import Env
import ProgramTest.Config
import ProgramTest.LoginSteps
import ProgramTest.Query
import ProgramTest.Start
import Types exposing (FrontendMsg(..))
import Url exposing (Protocol(..), Url)
import Wiki


story29WikiLoginUrl : Url
story29WikiLoginUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/Story29Wiki/login"
    , query = Nothing
    , fragment = Nothing
    }


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "29 — host admin create hosted wiki /admin/wikis/new"
        , config = ProgramTest.Config.emptyConfig
        , sessionId = "session-story29-create-wiki"
        , path = "/admin"
        , connectClientMs = Just 200
        , clientSteps =
            \client ->
                List.concat
                    [ [ client.input 100 (Effect.Browser.Dom.id "host-admin-login-password") Env.hostAdminPassword
                      , client.click 100 (Effect.Browser.Dom.id "host-admin-login-submit")
                      , client.checkView 300
                            (ProgramTest.Query.withinId "host-admin-wikis-list"
                                ProgramTest.Query.expectEmpty
                            )
                      , client.clickLink 100 Wiki.hostAdminNewWikiUrlPath
                      , client.checkView 200
                            (ProgramTest.Query.withinId "host-admin-create-wiki-page"
                                ProgramTest.Query.expectEmpty
                            )
                      , client.input 100 (Effect.Browser.Dom.id "host-admin-create-wiki-slug") "Story29Wiki"
                      , client.input 100 (Effect.Browser.Dom.id "host-admin-create-wiki-name") "Story 29 Wiki"
                      , client.input 100 (Effect.Browser.Dom.id "host-admin-create-wiki-initial-admin-username") "story29admin"
                      , client.input 100 (Effect.Browser.Dom.id "host-admin-create-wiki-initial-admin-password") "password12"
                      , client.click 100 (Effect.Browser.Dom.id "host-admin-create-wiki-submit")
                      , client.checkView 400
                            (ProgramTest.Query.withinHostAdminWikiRow "Story29Wiki"
                                (ProgramTest.Query.expectHasText "Story 29 Wiki")
                            )
                      , client.update 100 (UrlChanged story29WikiLoginUrl)
                      , client.checkView 300
                            (ProgramTest.Query.expectWikiLoginPageShowsSlug "Story29Wiki")
                      ]
                    , ProgramTest.LoginSteps.submitWikiLoginForm
                        { username = "story29admin"
                        , password = "password12"
                        }
                        client
                    , [ client.checkView 400
                            (ProgramTest.Query.expectPageShowsWikiSlug "wiki-home-page" "Story29Wiki")
                      ]
                    ]
        }
    ]
