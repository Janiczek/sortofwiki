module ProgramTest.Story47_FrontendRouteGuards exposing (endToEndTests)

import Backend
import Dict
import Effect.Browser.Dom
import Effect.Lamdera
import Effect.Test
import Effect.Time
import Env
import Frontend
import Html.Attributes
import ProgramTest.Config
import RemoteData
import Route
import Test.Html.Query
import Test.Html.Selector
import Types exposing (FrontendMsg(..), ToBackend, ToFrontend)
import Url exposing (Protocol(..), Url)


loginWithRedirectUrl : Url
loginWithRedirectUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/demo/login"
    , query = Just "redirect=%2Fw%2Fdemo"
    , fragment = Nothing
    }


wikiHomeUrl : Url
wikiHomeUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/demo"
    , query = Nothing
    , fragment = Nothing
    }


hostNewWikiUrl : Url
hostNewWikiUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/admin/wikis/new"
    , query = Nothing
    , fragment = Nothing
    }


adminUrl : Url
adminUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/admin"
    , query = Nothing
    , fragment = Nothing
    }


hostWikiElmTipsUrl : Url
hostWikiElmTipsUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/admin/wikis/elm-tips"
    , query = Nothing
    , fragment = Nothing
    }


endToEndTests : List (Effect.Test.EndToEndTest ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
endToEndTests =
    [ Effect.Test.start
        "47 — anonymous /review becomes login with redirect; no review queue fetch"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story47-anon-review")
            "/w/demo/review"
            { width = 800, height = 600 }
            (\client ->
                [ client.checkModel 400
                    (\model ->
                        case model.route of
                            Route.WikiLogin "demo" (Just "/w/demo/review") ->
                                case Dict.get "demo" model.store.reviewQueues of
                                    Nothing ->
                                        Ok ()

                                    Just _ ->
                                        Err "review queue should not be requested before login"

                            _ ->
                                Err "expected gated login route with redirect back to review"
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-login-page" ]
                            |> Test.Html.Query.has
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-wiki-slug" "demo") ]
                    )
                ]
            )
        ]
    , Effect.Test.start
        "47 — login with redirect navigates to return path after success"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story47-login-redirect")
            "/w/demo/login"
            { width = 800, height = 600 }
            (\client ->
                [ client.update 100 (UrlChanged loginWithRedirectUrl)
                , client.input 100 (Effect.Browser.Dom.id "wiki-login-username") "trustedpub"
                , client.input 100 (Effect.Browser.Dom.id "wiki-login-password") "password12"
                , client.click 100 (Effect.Browser.Dom.id "wiki-login-submit")
                , client.update 100 (UrlChanged wikiHomeUrl)
                , client.checkView 400
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-home-page" ]
                            |> Test.Html.Query.has
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-wiki-slug" "demo") ]
                    )
                ]
            )
        ]
    , Effect.Test.start
        "47 — anonymous /admin/wikis/new ends on host login with redirect"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            200
            (Effect.Lamdera.sessionIdFromString "session-story47-host-new")
            "/admin/wikis/new"
            { width = 800, height = 600 }
            (\client ->
                [ client.update 100 (UrlChanged hostNewWikiUrl)
                , client.checkModel 500
                    (\model ->
                        case model.route of
                            Route.HostAdmin (Just "/admin/wikis/new") ->
                                Ok ()

                            _ ->
                                Err "expected host admin login route preserving return path"
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "host-admin-login-password" ]
                            |> Test.Html.Query.has []
                    )
                ]
            )
        ]
    , Effect.Test.start
        "47 — anonymous /admin/wikis/elm-tips ends on host login with redirect"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            202
            (Effect.Lamdera.sessionIdFromString "session-story47-host-wiki-detail-anon")
            "/admin/wikis/elm-tips"
            { width = 800, height = 600 }
            (\client ->
                [ client.update 100 (UrlChanged hostWikiElmTipsUrl)
                , client.checkModel 500
                    (\model ->
                        case model.route of
                            Route.HostAdmin (Just "/admin/wikis/elm-tips") ->
                                Ok ()

                            _ ->
                                Err "expected host admin login route preserving return path to wiki detail"
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "host-admin-login-password" ]
                            |> Test.Html.Query.has []
                    )
                ]
            )
        ]
    , Effect.Test.start
        "47 — host-authenticated cold open /admin/wikis/elm-tips loads detail (not NotAsked ellipsis)"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            203
            (Effect.Lamdera.sessionIdFromString "session-story47-host-wiki-detail-auth")
            "/admin"
            { width = 800, height = 600 }
            (\client ->
                [ client.update 100 (UrlChanged adminUrl)
                , client.input 100 (Effect.Browser.Dom.id "host-admin-login-password") Env.hostAdminPassword
                , client.click 100 (Effect.Browser.Dom.id "host-admin-login-submit")
                , client.checkView 300
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "host-admin-wikis-list" ]
                            |> Test.Html.Query.has []
                    )
                ]
            )
        , Effect.Test.connectFrontend
            204
            (Effect.Lamdera.sessionIdFromString "session-story47-host-wiki-detail-auth")
            "/admin/wikis/elm-tips"
            { width = 800, height = 600 }
            (\client ->
                [ client.update 100 (UrlChanged hostWikiElmTipsUrl)
                , client.checkModel 500
                    (\model ->
                        case model.hostAdminWikiDetailDraft.load of
                            RemoteData.NotAsked ->
                                Err "detail load should not stay NotAsked after cold open (RequestHostWikiDetail must apply)"

                            _ ->
                                Ok ()
                    )
                , client.checkView 400
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "host-admin-wiki-detail-slug" ]
                            |> Test.Html.Query.has
                                [ Test.Html.Selector.attribute (Html.Attributes.value "elm-tips") ]
                    )
                ]
            )
        ]
    ]
