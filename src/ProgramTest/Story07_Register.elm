module ProgramTest.Story07_Register exposing (endToEndTests)

import Effect.Browser.Dom
import ProgramTest.Config
import ProgramTest.Query
import ProgramTest.Start


endToEndTests : List ProgramTest.Start.EndToEndTest
endToEndTests =
    [ ProgramTest.Start.start
        { name = "7 — register contributor /w/Demo/register"
        , config = ProgramTest.Config.demoWikiPagesOnly
        , sessionId = "session-story07-register"
        , path = "/w/Demo/register"
        , connectClientMs = Nothing
        , clientSteps =
            \client ->
                [ client.checkView 100
                    (ProgramTest.Query.expectPageShowsWikiSlug "wiki-register-page" "Demo")
                , client.input 100 (Effect.Browser.Dom.id "wiki-register-username") "story07alice"
                , client.input 100 (Effect.Browser.Dom.id "wiki-register-password") "password12"
                , client.click 100 (Effect.Browser.Dom.id "wiki-register-submit")
                , client.checkView 300
                    (ProgramTest.Query.withinId "wiki-register-success"
                        (ProgramTest.Query.expectHasText "Registration complete")
                    )
                ]
        }
    ]
