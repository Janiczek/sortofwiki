module ProgramTest.Story09_NewPageSubmission exposing (endToEndTests)

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


demoPagesUrl : Url
demoPagesUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/demo/pages"
    , query = Nothing
    , fragment = Nothing
    }


pendingPageUrl : Url
pendingPageUrl =
    { protocol = Http
    , host = "localhost"
    , port_ = Just 8000
    , path = "/w/demo/p/story09newpage"
    , query = Nothing
    , fragment = Nothing
    }


endToEndTests : List (Effect.Test.EndToEndTest ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
endToEndTests =
    [ Effect.Test.start
        "9 — submit new page draft stays off public index"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story09-submit")
            "/w/demo/register"
            { width = 800, height = 600 }
            (\client ->
                [ client.input 100 (Effect.Browser.Dom.id "wiki-register-username") "story09user"
                , client.input 100 (Effect.Browser.Dom.id "wiki-register-password") "password12"
                , client.click 100 (Effect.Browser.Dom.id "wiki-register-submit")
                , client.checkView 300
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-register-success" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Registration complete" ]
                    )
                , client.update 100 (UrlChanged submitNewUrl)
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-submit-new-page" ]
                            |> Test.Html.Query.has
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-wiki-slug" "demo") ]
                    )
                , client.input 100 (Effect.Browser.Dom.id "wiki-submit-new-slug") "story09newpage"
                , client.input 100 (Effect.Browser.Dom.id "wiki-submit-new-markdown") "# Story 09 page"
                , client.click 100 (Effect.Browser.Dom.id "wiki-submit-new-submit")
                , client.checkView 300
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-submit-new-success" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "sub_1" ]
                    )
                , client.update 100 (UrlChanged demoPagesUrl)
                , client.checkView 200
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "pages-list-page-list" ]
                            |> Test.Html.Query.findAll
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-page-slug" "story09newpage") ]
                            |> Test.Html.Query.count (Expect.equal 0)
                    )
                , client.update 100 (UrlChanged pendingPageUrl)
                , client.checkView 200
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "not-found-page" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Page not found" ]
                    )
                ]
            )
        ]
    ]
