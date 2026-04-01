module ProgramTest.Story01_WikiList exposing (endToEndTests)

import Effect.Lamdera
import Effect.Test
import Effect.Time
import Html.Attributes
import ProgramTest.Config
import Test.Html.Query
import Test.Html.Selector
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)


endToEndTests : List (Effect.Test.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
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
                            |> Test.Html.Query.find [ Test.Html.Selector.id "catalog-page" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Hosted wikis" ]
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
