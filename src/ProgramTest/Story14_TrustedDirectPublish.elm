module ProgramTest.Story14_TrustedDirectPublish exposing (endToEndTests)

import Backend
import Effect.Browser.Dom
import Effect.Lamdera
import Effect.Test
import Effect.Time
import Expect
import Frontend
import Html.Attributes
import ProgramTest.Config
import Test.Html.Query
import Test.Html.Selector
import Types exposing (FrontendMsg(..), ToBackend, ToFrontend)
import Url exposing (Protocol(..), Url)


submitNewUrl : Url
submitNewUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/demo/submit/new"
    , query = Nothing
    , fragment = Nothing
    }


demoWikiHomeUrl : Url
demoWikiHomeUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/demo"
    , query = Nothing
    , fragment = Nothing
    }


publishedPageUrl : Url
publishedPageUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/demo/p/Story14TrustedPage"
    , query = Nothing
    , fragment = Nothing
    }


endToEndTests : List (Effect.Test.EndToEndTest ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
endToEndTests =
    [ Effect.Test.start
        "14 — trusted contributor new page is public without review"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story14-trusted-new")
            "/w/demo/login"
            { width = 800, height = 600 }
            (\client ->
                [ client.input 100 (Effect.Browser.Dom.id "wiki-login-username") "trustedpub"
                , client.input 100 (Effect.Browser.Dom.id "wiki-login-password") "password12"
                , client.click 100 (Effect.Browser.Dom.id "wiki-login-submit")
                , client.checkView 300
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-login-success" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "You are logged in" ]
                    )
                , client.update 100 (UrlChanged submitNewUrl)
                , client.input 100 (Effect.Browser.Dom.id "wiki-submit-new-slug") "Story14TrustedPage"
                , client.input 100 (Effect.Browser.Dom.id "wiki-submit-new-markdown") "# Story 14 trusted publish"
                , client.click 100 (Effect.Browser.Dom.id "wiki-submit-new-submit")
                , client.checkView 300
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-submit-new-success" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Published" ]
                    )
                , client.update 100 (UrlChanged demoWikiHomeUrl)
                , client.checkView 200
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-home-page-slugs" ]
                            |> Test.Html.Query.findAll
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-page-slug" "Story14TrustedPage") ]
                            |> Test.Html.Query.count (Expect.equal 1)
                    )
                , client.update 100 (UrlChanged publishedPageUrl)
                , client.checkView 200
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "page-markdown" ]
                            |> Test.Html.Query.find [ Test.Html.Selector.tag "h1" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Story 14 trusted publish" ]
                    )
                ]
            )
        ]
    ]
