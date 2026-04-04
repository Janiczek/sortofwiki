module ProgramTest.Story08_Login exposing (endToEndTests)

import Dict
import Effect.Browser.Dom
import ProgramTest.Config
import ProgramTest.Actions
import ProgramTest.Model
import ProgramTest.Query
import ProgramTest.Start
import Route
import Types exposing (FrontendMsg(..))
import Url exposing (Protocol(..), Url)
import Wiki


demoLoginPathUrl : Url
demoLoginPathUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/Demo/login"
    , query = Nothing
    , fragment = Nothing
    }


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "Login on a wiki"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story08-login"
        , path = "/w/Demo/register"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                List.concat
                    [ [ client.checkView 100 (ProgramTest.Query.expectPageShowsWikiSlug "wiki-register-page" "Demo")
                      , client.input 100 (Effect.Browser.Dom.id "wiki-register-username") "story08user"
                      , client.input 100 (Effect.Browser.Dom.id "wiki-register-password") "password12"
                      , client.click 100 (Effect.Browser.Dom.id "wiki-register-submit")
                      , client.checkView 400
                            (ProgramTest.Query.expectAll
                                [ ProgramTest.Query.expectWikiHomePageShowsSlug "Demo"
                                , ProgramTest.Query.withinId "wiki-logout-button"
                                    (ProgramTest.Query.expectHasText "Log out")
                                ]
                            )
                      , client.click 100 (Effect.Browser.Dom.id "wiki-logout-button")
                      , client.clickLink 100 (Wiki.loginUrlPath "Demo")
                      , client.checkView 100 (ProgramTest.Query.expectWikiLoginPageShowsSlug "Demo")
                      ]
                    , ProgramTest.Actions.submitWikiLoginForm
                        { username = "story08user"
                        , password = "password12"
                        }
                        client
                    , [ client.checkView 400 (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      ]
                    ]
        }
    , ProgramTest.Start.start
        { name = "Logged in user can't see login form"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story08-login-redirect-away"
        , path = "/w/Demo/login"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                List.concat
                    [ ProgramTest.Actions.submitWikiLoginForm
                        { username = "trustedpub"
                        , password = "password12"
                        }
                        client
                    , [ client.checkView 400
                            (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      , client.update 100 (UrlChanged demoLoginPathUrl)
                      , client.checkView 400
                            (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      , client.checkModel 100
                            (ProgramTest.Model.expectRoute (Route.WikiHome "Demo")
                                "expected WikiHome demo after login guard on /login"
                            )
                      ]
                    ]
        }
    , ProgramTest.Start.start
        { name = "Logged in user can log out"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story08-logout"
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
                    , [ client.checkView 400
                            (ProgramTest.Query.withinId "wiki-logout-button"
                                (ProgramTest.Query.expectHasText "Log out")
                            )
                      , client.click 100 (Effect.Browser.Dom.id "wiki-logout-button")
                      , client.checkView 400
                            (ProgramTest.Query.withinHref (Wiki.loginUrlPath "Demo")
                                (ProgramTest.Query.expectHasText "Log in")
                            )
                      , client.checkModel 100
                            (\model ->
                                if Dict.isEmpty model.contributorWikiSessions then
                                    Ok ()

                                else
                                    Err "expected contributor sessions cleared after logout"
                            )
                      ]
                    ]
        }
    ]
