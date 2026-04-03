module ProgramTest.Story06_OnlyPublished exposing (endToEndTests)

import Backend
import Effect.Lamdera
import Effect.Test
import Effect.Time
import Expect
import Frontend
import Html.Attributes
import ProgramTest.Config
import Test.Html.Query
import Test.Html.Selector
import Types exposing (ToBackend, ToFrontend)


endToEndTests : List (Effect.Test.EndToEndTest ToBackend Frontend.Msg Frontend.Model ToFrontend Backend.Msg Backend.Model)
endToEndTests =
    [ Effect.Test.start
        "6 — published body on /w/demo/p/Home, pending text absent"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story06-home")
            "/w/demo/p/Home"
            { width = 800, height = 600 }
            (\client ->
                [ client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "page-markdown" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Welcome to the Demo Wiki" ]
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.hasNot [ Test.Html.Selector.text "STORY06_PENDING_LEAK" ]
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.hasNot [ Test.Html.Selector.text "STORY06_PENDING_ONLY" ]
                    )
                ]
            )
        ]
    , Effect.Test.start
        "6 — pending-only slug 404 at /w/demo/p/OnlyPending"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story06-pending-only")
            "/w/demo/p/OnlyPending"
            { width = 800, height = 600 }
            (\client ->
                [ client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-context" "layout-header") ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Page not found" ]
                    )
                , client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.hasNot [ Test.Html.Selector.text "STORY06_PENDING_ONLY" ]
                    )
                ]
            )
        ]
    , Effect.Test.start
        "6 — wiki home table omits pending-only slug"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story06-pages-list")
            "/w/demo"
            { width = 800, height = 600 }
            (\client ->
                [ client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-home-page-slugs" ]
                            |> Test.Html.Query.findAll
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-page-slug" "OnlyPending") ]
                            |> Test.Html.Query.count (Expect.equal 0)
                    )
                ]
            )
        ]
    ]
