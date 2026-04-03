module ProgramTest.Story24_RevokeWikiAdmin exposing (endToEndTests)

import Backend
import Dict
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
import WikiRole


expectGrantadminTrustedOnDemo : Backend.Model -> Result String ()
expectGrantadminTrustedOnDemo backendModel =
    case Dict.get "demo" backendModel.contributors of
        Nothing ->
            Err "missing demo contributors"

        Just byWiki ->
            case Dict.get "grantadmin_trusted" byWiki of
                Nothing ->
                    Err "missing grantadmin_trusted user"

                Just stored ->
                    case stored.role of
                        WikiRole.TrustedContributor ->
                            Ok ()

                        WikiRole.UntrustedContributor ->
                            Err "grantadmin_trusted should be Trusted after revoke"

                        WikiRole.Admin ->
                            Err "grantadmin_trusted should be Trusted after revoke (still Admin)"


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
        "24 — wiki admin grants then revokes another admin; target is trusted in registry"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story24-revoke-flow")
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
                , client.checkView 400
                    (\root ->
                        root
                            |> Test.Html.Query.find
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-admin-user" "wikidemo") ]
                            |> Test.Html.Query.hasNot
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-context" "wiki-admin-revoke-admin") ]
                    )
                , client.click 100
                    (Effect.Browser.Dom.id "wiki-admin-grant-admin-grantadmin_trusted")
                , client.checkView 600
                    (\root ->
                        root
                            |> Test.Html.Query.find
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-admin-user" "grantadmin_trusted") ]
                            |> Test.Html.Query.find
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-user-role" "Admin") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Admin" ]
                    )
                , client.click 100
                    (Effect.Browser.Dom.id "wiki-admin-revoke-admin-grantadmin_trusted")
                , client.checkView 600
                    (\root ->
                        root
                            |> Test.Html.Query.find
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-admin-user" "grantadmin_trusted") ]
                            |> Test.Html.Query.find
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-user-role" "Trusted") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Trusted" ]
                    )
                ]
            )
        , Effect.Test.checkBackend 0 expectGrantadminTrustedOnDemo
        ]
    ]
