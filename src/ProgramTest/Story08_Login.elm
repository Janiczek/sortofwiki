module ProgramTest.Story08_Login exposing (endToEndTests)

import Effect.Browser.Dom
import ProgramTest.Config
import ProgramTest.LoginSteps
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
        { name = "8 — login contributor /w/Demo/login"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story08-login"
        , path = "/w/Demo/register"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                List.concat
                    [ [ client.checkView 100
                            (ProgramTest.Query.expectPageShowsWikiSlug "wiki-register-page" "Demo")
                      , client.input 100 (Effect.Browser.Dom.id "wiki-register-username") "story08user"
                      , client.input 100 (Effect.Browser.Dom.id "wiki-register-password") "password12"
                      , client.click 100 (Effect.Browser.Dom.id "wiki-register-submit")
                      , client.checkView 300
                            (ProgramTest.Query.expectAll
                                [ ProgramTest.Query.withinId "wiki-register-success"
                                    (ProgramTest.Query.expectHasText "Registration complete")
                                , ProgramTest.Query.withinId "wiki-logout-button"
                                    (ProgramTest.Query.expectHasText "Log out")
                                ]
                            )
                      , client.click 100 (Effect.Browser.Dom.id "wiki-logout-button")
                      , client.clickLink 100 (Wiki.loginUrlPath "Demo")
                      , client.checkView 100
                            (ProgramTest.Query.expectWikiLoginPageShowsSlug "Demo")
                      ]
                    , ProgramTest.LoginSteps.submitWikiLoginForm
                        { username = "story08user"
                        , password = "password12"
                        }
                        client
                    , [ client.checkView 400
                            (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      ]
                    ]
        }
    , ProgramTest.Start.start
        { name = "8 — logged-in user visiting /w/Demo/login is redirected to wiki home"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story08-login-redirect-away"
        , path = "/w/Demo/login"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                List.concat
                    [ ProgramTest.LoginSteps.submitWikiLoginForm
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
                            (\model ->
                                case model.route of
                                    Route.WikiHome "Demo" ->
                                        Ok ()

                                    _ ->
                                        Err "expected WikiHome demo after login guard on /login"
                            )
                      ]
                    ]
        }
    , ProgramTest.Start.start
        { name = "8 — contributor can log out from wiki nav"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story08-logout"
        , path = "/"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                List.concat
                    [ ProgramTest.LoginSteps.loginToWiki
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
                                case model.contributorWikiSession of
                                    Nothing ->
                                        Ok ()

                                    Just _ ->
                                        Err "expected contributor session cleared after logout"
                            )
                      ]
                    ]
        }
    ]
