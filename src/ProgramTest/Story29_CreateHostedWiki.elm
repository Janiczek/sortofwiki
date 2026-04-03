module ProgramTest.Story29_CreateHostedWiki exposing (endToEndTests)

import Backend
import Effect.Browser.Dom
import Effect.Lamdera
import Effect.Test
import Effect.Time
import Env
import Frontend
import Html.Attributes
import ProgramTest.Config
import Test.Html.Query
import Test.Html.Selector
import Types exposing (FrontendMsg(..), ToBackend, ToFrontend)
import Url exposing (Protocol(..), Url)


adminUrl : Url
adminUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/admin"
    , query = Nothing
    , fragment = Nothing
    }


adminWikisNewUrl : Url
adminWikisNewUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/admin/wikis/new"
    , query = Nothing
    , fragment = Nothing
    }


adminWikisUrl : Url
adminWikisUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/admin/wikis"
    , query = Nothing
    , fragment = Nothing
    }


endToEndTests : List (Effect.Test.EndToEndTest ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
endToEndTests =
    [ Effect.Test.start
        "29 — host admin create hosted wiki /admin/wikis/new"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            200
            (Effect.Lamdera.sessionIdFromString "session-story29-create-wiki")
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
                , client.update 100 (UrlChanged adminWikisNewUrl)
                , client.checkView 200
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "host-admin-create-wiki-page" ]
                            |> Test.Html.Query.has []
                    )
                , client.input 100 (Effect.Browser.Dom.id "host-admin-create-wiki-slug") "Story29Wiki"
                , client.input 100 (Effect.Browser.Dom.id "host-admin-create-wiki-name") "Story 29 Wiki"
                , client.click 100 (Effect.Browser.Dom.id "host-admin-create-wiki-submit")
                , client.update 100 (UrlChanged adminWikisUrl)
                , client.checkView 400
                    (\root ->
                        root
                            |> Test.Html.Query.find
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-context" "host-admin-wiki-row")
                                , Test.Html.Selector.attribute (Html.Attributes.attribute "data-wiki-slug" "Story29Wiki")
                                ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Story 29 Wiki" ]
                    )
                ]
            )
        ]
    ]
