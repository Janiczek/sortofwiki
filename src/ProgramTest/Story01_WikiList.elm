module ProgramTest.Story01_WikiList exposing (endToEndTests)

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
        "1 — catalog on /"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-catalog")
            "/"
            { width = 800, height = 600 }
            (\client ->
                [ client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-context" "layout-header") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "SortOfWiki" ]
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "catalog-page" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.id "wiki-catalog" ]
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-wiki-slug" "demo") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Demo Wiki" ]
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-wiki-slug" "elm-tips") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Elm Tips" ]
                    )
                ]
            )
        ]
    ]
