module ProgramTest.Story04_PublishedPage exposing (endToEndTests)

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
        "4 — published page /w/demo/p/guides"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-published-page-guides")
            "/w/demo/p/guides"
            { width = 800, height = 600 }
            (\client ->
                [ client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "page-published-page" ]
                            |> Test.Html.Query.has
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-wiki-slug" "demo")
                                , Test.Html.Selector.attribute (Html.Attributes.attribute "data-page-slug" "guides")
                                ]
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "page-markdown" ]
                            |> Test.Html.Query.find [ Test.Html.Selector.tag "h2" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "How to use this wiki" ]
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "page-markdown" ]
                            |> Test.Html.Query.find [ Test.Html.Selector.tag "strong" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "manual" ]
                    )
                ]
            )
        ]
    , Effect.Test.start
        "4 — unknown page shows 404"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-published-page-missing")
            "/w/demo/p/no-such-page"
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
