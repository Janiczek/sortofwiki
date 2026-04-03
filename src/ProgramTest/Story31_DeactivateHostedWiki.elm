module ProgramTest.Story31_DeactivateHostedWiki exposing (endToEndTests)

import Backend
import Effect.Browser.Dom
import Effect.Lamdera
import Effect.Test
import Effect.Time
import Env
import Expect
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


adminWikiElmTipsUrl : Url
adminWikiElmTipsUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/admin/wikis/elm-tips"
    , query = Nothing
    , fragment = Nothing
    }


homeUrl : Url
homeUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/"
    , query = Nothing
    , fragment = Nothing
    }


elmTipsWikiHomeUrl : Url
elmTipsWikiHomeUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/elm-tips"
    , query = Nothing
    , fragment = Nothing
    }


endToEndTests : List (Effect.Test.EndToEndTest ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
endToEndTests =
    [ Effect.Test.start
        "31 — deactivate elm-tips: hidden from public catalog; /w/elm-tips is 404; host list shows Deactivated"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            200
            (Effect.Lamdera.sessionIdFromString "session-story31-deactivate-wiki")
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
                , client.update 100 (UrlChanged adminWikiElmTipsUrl)
                , client.checkView 400
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "host-admin-wiki-detail-status" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Active" ]
                    )
                , client.click 100 (Effect.Browser.Dom.id "host-admin-wiki-detail-deactivate")
                , client.checkView 400
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "host-admin-wiki-detail-status" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Deactivated" ]
                    )
                , client.update 100 (UrlChanged homeUrl)
                , client.checkView 400
                    (\root ->
                        root
                            |> Test.Html.Query.findAll
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-wiki-slug" "elm-tips") ]
                            |> Test.Html.Query.count (Expect.equal 0)
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-wiki-slug" "demo") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Demo Wiki" ]
                    )
                , client.update 100 (UrlChanged elmTipsWikiHomeUrl)
                , client.checkView 400
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-context" "layout-header") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Page not found" ]
                    )
                , client.update 100 (UrlChanged adminWikisUrl)
                , client.checkView 400
                    (\root ->
                        root
                            |> Test.Html.Query.find
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-context" "host-admin-wiki-row")
                                , Test.Html.Selector.attribute (Html.Attributes.attribute "data-wiki-slug" "elm-tips")
                                , Test.Html.Selector.attribute (Html.Attributes.attribute "data-wiki-active" "false")
                                ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Deactivated" ]
                    )
                ]
            )
        ]
    ]
