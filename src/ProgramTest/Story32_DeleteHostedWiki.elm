module ProgramTest.Story32_DeleteHostedWiki exposing (endToEndTests)

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


story32WikiDetailUrl : Url
story32WikiDetailUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/admin/wikis/Story32Wiki"
    , query = Nothing
    , fragment = Nothing
    }


endToEndTests : List (Effect.Test.EndToEndTest ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
endToEndTests =
    [ Effect.Test.start
        "32 — delete hosted wiki: wrong confirm fails; slug confirm removes wiki from list"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            200
            (Effect.Lamdera.sessionIdFromString "session-story32-delete-wiki")
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
                , client.input 100 (Effect.Browser.Dom.id "host-admin-create-wiki-slug") "Story32Wiki"
                , client.input 100 (Effect.Browser.Dom.id "host-admin-create-wiki-name") "Story 32 Wiki"
                , client.click 100 (Effect.Browser.Dom.id "host-admin-create-wiki-submit")
                , client.update 100 (UrlChanged adminWikisUrl)
                , client.checkView 400
                    (\root ->
                        root
                            |> Test.Html.Query.find
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-context" "host-admin-wiki-row")
                                , Test.Html.Selector.attribute (Html.Attributes.attribute "data-wiki-slug" "Story32Wiki")
                                ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Story 32 Wiki" ]
                    )
                , client.update 100 (UrlChanged story32WikiDetailUrl)
                , client.checkView 400
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "host-admin-wiki-detail-page" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-wiki-slug" "Story32Wiki") ]
                    )
                , client.input 100 (Effect.Browser.Dom.id "host-admin-delete-wiki-confirm") "not-the-slug"
                , client.click 100 (Effect.Browser.Dom.id "host-admin-delete-wiki-submit")
                , client.checkView 400
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "host-admin-delete-wiki-error" ]
                            |> Test.Html.Query.has
                                [ Test.Html.Selector.text "Confirmation must match the wiki slug or the word DELETE." ]
                    )
                , client.input 100 (Effect.Browser.Dom.id "host-admin-delete-wiki-confirm") "Story32Wiki"
                , client.click 100 (Effect.Browser.Dom.id "host-admin-delete-wiki-submit")
                , client.update 100 (UrlChanged adminWikisUrl)
                , client.checkView 400
                    (\root ->
                        root
                            |> Test.Html.Query.findAll
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-wiki-slug" "Story32Wiki") ]
                            |> Test.Html.Query.count (Expect.equal 0)
                    )
                ]
            )
        ]
    ]
