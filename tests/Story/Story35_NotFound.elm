module Story.Story35_NotFound exposing (endToEndTests, suite)

import Effect.Lamdera
import Effect.Test
import Effect.Time
import ProgramTestHelpers
import Test exposing (Test)
import Test.Html.Query
import Test.Html.Selector
import Types exposing (BackendModel, BackendMsg, FrontendModel, FrontendMsg, ToBackend, ToFrontend)


endToEndTests : List (Effect.Test.EndToEndTest ToBackend FrontendMsg FrontendModel ToFrontend BackendMsg BackendModel)
endToEndTests =
    [ Effect.Test.start
        "35 — 404 for unknown URL"
        (Effect.Time.millisToPosix 0)
        ProgramTestHelpers.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-404")
            "/no-such-page"
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


suite : Test
suite =
    Test.describe "Story 35 — 404 unknown URL"
        (List.map Effect.Test.toTest endToEndTests)
