module ProgramTest.Story27_HostAdminLogin exposing (endToEndTests)

import Backend
import Effect.Browser.Dom
import Effect.Lamdera
import Effect.Test
import Effect.Time
import Env
import Frontend
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
        "27 — host admin login /admin"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            200
            (Effect.Lamdera.sessionIdFromString "session-story27-host-admin")
            "/admin"
            { width = 800, height = 600 }
            (\client ->
                [ client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "host-admin-login-page" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Platform host admin" ]
                    )
                , client.update 100 (UrlChanged adminWikisUrl)
                , client.checkView 200
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "host-admin-wikis-forbidden" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Host admin sign-in required." ]
                    )
                , client.update 100 (UrlChanged adminUrl)
                , client.input 100 (Effect.Browser.Dom.id "host-admin-login-password") "wrong-password"
                , client.click 100 (Effect.Browser.Dom.id "host-admin-login-submit")
                , client.checkView 200
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "host-admin-login-error" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Invalid password." ]
                    )
                , client.input 100 (Effect.Browser.Dom.id "host-admin-login-password") Env.hostAdminPassword
                , client.click 100 (Effect.Browser.Dom.id "host-admin-login-submit")
                , client.checkView 300
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "host-admin-login-success" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Signed in as platform host admin." ]
                    )
                ]
            )
        ]
    ]
