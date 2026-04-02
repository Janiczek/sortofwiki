module ProgramTest.Story20_AdminUsers exposing (endToEndTests)

import Backend
import Effect.Browser.Dom
import Effect.Lamdera
import Effect.Test
import Effect.Time
import Frontend
import Html.Attributes
import ProgramTest.Config
import Test.Html.Query
import Test.Html.Selector
import Types exposing (FrontendMsg(..), ToBackend, ToFrontend)
import Url exposing (Protocol(..), Url)
import Wiki


adminUsersUrl : Url
adminUsersUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = Wiki.adminUsersUrlPath "demo"
    , query = Nothing
    , fragment = Nothing
    }


endToEndTests : List (Effect.Test.EndToEndTest ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
endToEndTests =
    [ Effect.Test.start
        "20 — wiki admin opens /w/demo/admin/users and sees contributors"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story20-admin-users")
            "/w/demo/login"
            { width = 800, height = 600 }
            (\client ->
                [ client.input 100 (Effect.Browser.Dom.id "wiki-login-username") "wikidemo"
                , client.input 100 (Effect.Browser.Dom.id "wiki-login-password") "password12"
                , client.click 100 (Effect.Browser.Dom.id "wiki-login-submit")
                , client.checkView 300
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-login-success" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "You are logged in" ]
                    )
                , client.update 100 (UrlChanged adminUsersUrl)
                , client.checkView 500
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-admin-users-page" ]
                            |> Test.Html.Query.has
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-wiki-slug" "demo") ]
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-admin-user" "statusdemo") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "statusdemo" ]
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-admin-user" "trustedpub") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "trustedpub" ]
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-admin-user" "wikidemo") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "wikidemo" ]
                    )
                ]
            )
        ]
    ]
