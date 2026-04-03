module ProgramTest.Story05_Backlinks exposing (endToEndTests)

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
        "5 — backlinks on published page /w/demo/p/Guides"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-backlinks-guides")
            "/w/demo/p/Guides"
            { width = 800, height = 600 }
            (\client ->
                [ client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "page-backlinks" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Backlinks" ]
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "page-backlinks-list" ]
                            |> Test.Html.Query.find [ Test.Html.Selector.attribute (Html.Attributes.href "/w/demo/p/Home") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-backlink-page-slug" "Home") ]
                    )
                ]
            )
        ]
    , Effect.Test.start
        "5 — backlinks on home list pages that link here (about → home, not reciprocated)"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-backlinks-home")
            "/w/demo/p/Home"
            { width = 800, height = 600 }
            (\client ->
                [ client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "page-backlinks-list" ]
                            |> Test.Html.Query.find [ Test.Html.Selector.attribute (Html.Attributes.href "/w/demo/p/About") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-backlink-page-slug" "About") ]
                    )
                ]
            )
        ]
    , Effect.Test.start
        "5 — backlinks empty state on single-page wiki /w/elm-tips/p/Home"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-backlinks-elm-tips-home")
            "/w/elm-tips/p/Home"
            { width = 800, height = 600 }
            (\client ->
                [ client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "page-backlinks" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "No backlinks." ]
                    )
                ]
            )
        ]
    ]
