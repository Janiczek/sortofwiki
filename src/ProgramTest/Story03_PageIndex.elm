module ProgramTest.Story03_PageIndex exposing (endToEndTests)

import Backend
import Effect.Lamdera
import Effect.Test
import Effect.Time
import Frontend
import Html.Attributes
import ProgramTest.Config
import Test.Html.Query
import Test.Html.Selector
import Types exposing (ToBackend, ToFrontend)


endToEndTests : List (Effect.Test.EndToEndTest ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
endToEndTests =
    [ Effect.Test.start
        "3 — pages list /w/demo/pages"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-pages-list-demo")
            "/w/demo/pages"
            { width = 800, height = 600 }
            (\client ->
                [ client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "pages-list-page" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Demo Wiki — Pages" ]
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-wiki-slug" "demo") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "guides" ]
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.attribute (Html.Attributes.href "/w/demo/p/guides") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-page-slug" "guides") ]
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.attribute (Html.Attributes.href "/w/demo/p/home") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-page-slug" "home") ]
                    )
                ]
            )
        ]
    , Effect.Test.start
        "3 — unknown wiki pages URL shows 404"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-pages-list-unknown")
            "/w/unknown-slug/pages"
            { width = 800, height = 600 }
            (\client ->
                [ client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "not-found-page" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Page not found" ]
                    )
                ]
            )
        ]
    ]
