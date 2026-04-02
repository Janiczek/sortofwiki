module ProgramTest.Story28_HostWikiList exposing (endToEndTests)

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
        "28 — host admin wiki list /admin/wikis"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            200
            (Effect.Lamdera.sessionIdFromString "session-story28-host-wikis")
            "/admin"
            { width = 800, height = 600 }
            (\client ->
                [ client.update 100 (UrlChanged adminUrl)
                , client.input 100 (Effect.Browser.Dom.id "host-admin-login-password") Env.hostAdminPassword
                , client.click 100 (Effect.Browser.Dom.id "host-admin-login-submit")
                , client.checkView 300
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "host-admin-login-success" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Signed in as platform host admin." ]
                    )
                , client.update 100 (UrlChanged adminWikisUrl)
                , client.checkView 400
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "host-admin-wikis-list" ]
                            |> Test.Html.Query.has []
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find
                                [ Test.Html.Selector.class "host-admin-wiki-row"
                                , Test.Html.Selector.attribute (Html.Attributes.attribute "data-wiki-slug" "demo")
                                ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Demo Wiki" ]
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find
                                [ Test.Html.Selector.class "host-admin-wiki-row"
                                , Test.Html.Selector.attribute (Html.Attributes.attribute "data-wiki-slug" "elm-tips")
                                ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Elm Tips" ]
                    )
                ]
            )
        ]
    ]
