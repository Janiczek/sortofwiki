module ProgramTest.Story30_EditHostedWikiMetadata exposing (endToEndTests)

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


adminWikiDemoUrl : Url
adminWikiDemoUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/admin/wikis/demo"
    , query = Nothing
    , fragment = Nothing
    }


endToEndTests : List (Effect.Test.EndToEndTest ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
endToEndTests =
    [ Effect.Test.start
        "30 — host admin edit demo wiki summary and slug policy"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            200
            (Effect.Lamdera.sessionIdFromString "session-story30-host-wiki-metadata")
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
                , client.update 100 (UrlChanged adminWikiDemoUrl)
                , client.checkView 400
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "host-admin-wiki-detail-page" ]
                            |> Test.Html.Query.has []
                    )
                , client.input 100 (Effect.Browser.Dom.id "host-admin-wiki-detail-summary") "STORY30_UPDATED_SUMMARY"
                , client.update 100 (HostAdminWikiDetailSlugPolicyFormChanged "AllowAny")
                , client.click 100 (Effect.Browser.Dom.id "host-admin-wiki-detail-save")
                , client.checkView 400
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "host-admin-wiki-detail-summary-display" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "STORY30_UPDATED_SUMMARY" ]
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "host-admin-wiki-detail-policy-display" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Allow any slug characters (legacy)" ]
                    )
                ]
            )
        ]
    ]
