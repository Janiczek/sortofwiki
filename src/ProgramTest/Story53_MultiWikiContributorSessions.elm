module ProgramTest.Story53_MultiWikiContributorSessions exposing (endToEndTests)

import Backend
import Dict
import Effect.Test
import Frontend
import ProgramTest.Actions
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start
import Types exposing (FrontendMsg(..), ToBackend, ToFrontend)
import Url exposing (Protocol(..), Url)
import Wiki


catalogUrl : Url
catalogUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/"
    , query = Nothing
    , fragment = Nothing
    }


demoWikiHomeUrl : Url
demoWikiHomeUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/Demo"
    , query = Nothing
    , fragment = Nothing
    }


{-| Log in when the client already opened on `wikiHomeUrlPath` (skips catalog navigation).
-}
loginToWikiFromHome :
    { wikiSlug : Wiki.Slug
    , username : String
    , password : String
    }
    -> Effect.Test.FrontendActions ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model
    -> List (Effect.Test.Action ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
loginToWikiFromHome creds client =
    List.concat
        [ [ client.checkView 400
                (ProgramTest.Query.expectWikiHomePageShowsSlug creds.wikiSlug)
          , client.clickLink 100 (Wiki.loginUrlPath creds.wikiSlug)
          , client.checkView 200
                (ProgramTest.Query.expectWikiLoginPageShowsSlug creds.wikiSlug)
          ]
        , ProgramTest.Actions.submitWikiLoginForm
            { username = creds.username
            , password = creds.password
            }
            client
        ]


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    ProgramTest.Start.bothViewports
        { baseName = "Same browser session can stay logged in to two wikis"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story53-multi-wiki"
        , path = "/w/Demo"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                List.concat
                    [ loginToWikiFromHome
                        { wikiSlug = "Demo"
                        , username = "demo_trusted_publisher"
                        , password = "password12"
                        }
                        client
                    , [ client.checkView 400 (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      , client.checkModel 200
                            (\model ->
                                if Dict.member "Demo" model.contributorWikiSessions && not (Dict.member "ElmTips" model.contributorWikiSessions) then
                                    Ok ()

                                else
                                    Err "expected only Demo contributor session after first login"
                            )
                      , client.update 100 (UrlChanged catalogUrl)
                      , client.checkView 400
                            (ProgramTest.Query.withinWikiCatalogRow "ElmTips"
                                (ProgramTest.Query.expectHasText (Wiki.wikiHomeUrlPath "ElmTips"))
                            )
                      ]
                    , ProgramTest.Actions.navigateToWikiHome "ElmTips" client
                    , [ client.checkView 400 (ProgramTest.Query.expectWikiHomePageShowsSlug "ElmTips")
                      , client.clickLink 100 (Wiki.loginUrlPath "ElmTips")
                      , client.checkView 200 (ProgramTest.Query.expectWikiLoginPageShowsSlug "ElmTips")
                      ]
                    , ProgramTest.Actions.submitWikiLoginForm
                        { username = "elmtipsadmin"
                        , password = "password12"
                        }
                        client
                    , [ client.checkView 400 (ProgramTest.Query.expectWikiHomePageShowsSlug "ElmTips")
                      , client.checkModel 200
                            (\model ->
                                case ( Dict.get "Demo" model.contributorWikiSessions, Dict.get "ElmTips" model.contributorWikiSessions ) of
                                    ( Just demoS, Just elmS ) ->
                                        if demoS.displayUsername == "demo_trusted_publisher" && elmS.displayUsername == "elmtipsadmin" then
                                            Ok ()

                                        else
                                            Err "unexpected display usernames on per-wiki sessions"

                                    _ ->
                                        Err "expected contributor sessions for both Demo and ElmTips"
                            )
                      , client.checkView 300
                            (ProgramTest.Query.expectAll
                                [ ProgramTest.Query.withinId "wiki-logout-button"
                                    (ProgramTest.Query.expectHasText "Logout")
                                , ProgramTest.Query.expectHasText "@elmtipsadmin"
                                ]
                            )
                      , client.update 100 (UrlChanged demoWikiHomeUrl)
                      , client.checkView 400 (ProgramTest.Query.expectWikiHomePageShowsSlug "Demo")
                      , client.checkView 300
                            (ProgramTest.Query.expectHasText "@demo_trusted_publisher")
                      ]
                    ]
        }
