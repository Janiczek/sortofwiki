module ProgramTest.Story02_WikiHome exposing (endToEndTests)

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
        "2 — wiki home /w/demo"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-wiki-demo")
            "/w/demo"
            { width = 800, height = 600 }
            (\client ->
                [ client.checkView 200
                    (\root ->
                        root
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Demo Wiki" ]
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-home-page" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Pages" ]
                    )
                ]
            )
        ]
    , Effect.Test.start
        "2 — unknown wiki slug shows 404"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-wiki-unknown")
            "/w/unknown-slug"
            { width = 800, height = 600 }
            (\client ->
                [ client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-context" "layout-header") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Page not found" ]
                    )
                ]
            )
        ]
    ]
