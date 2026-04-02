module ProgramTest.Story07_Register exposing (endToEndTests)

import Backend
import Effect.Browser.Dom
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
        "7 — register contributor /w/demo/register"
        (Effect.Time.millisToPosix 0)
        ProgramTest.Config.config
        [ Effect.Test.connectFrontend
            100
            (Effect.Lamdera.sessionIdFromString "session-story07-register")
            "/w/demo/register"
            { width = 800, height = 600 }
            (\client ->
                [ client.checkView 100
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-register-page" ]
                            |> Test.Html.Query.has
                                [ Test.Html.Selector.attribute (Html.Attributes.attribute "data-wiki-slug" "demo") ]
                    )
                , client.input 100 (Effect.Browser.Dom.id "wiki-register-username") "story07alice"
                , client.input 100 (Effect.Browser.Dom.id "wiki-register-password") "password12"
                , client.click 100 (Effect.Browser.Dom.id "wiki-register-submit")
                , client.checkView 300
                    (\root ->
                        root
                            |> Test.Html.Query.find [ Test.Html.Selector.id "wiki-register-success" ]
                            |> Test.Html.Query.has [ Test.Html.Selector.text "Registration complete" ]
                    )
                ]
            )
        ]
    ]
